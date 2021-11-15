--[[
The functional portion of the output-hass application.
Karl Palsson, Nov 2021 <karlp@tweak.net.au>

--]]

local uci = require("uci")
local json = require("cjson.safe")
-- cjson specific
json.encode_sparse_array(true)
local mosq = require("mosquitto") -- only used for topic matching.
local pl = require("pl.import_into")()
local PU = require("posix.unistd")
local ugly = require("remake.uglylog")

local M = {}
M.__index = M

-- key is by logical hass name, _NOT_ by et-topic names
-- keys are:
-- * u for unit, in hass terms.
-- * perp for "per point", true if you need one of these per point
-- * et for the etactica topic key.
local data_types = {
    power = {u="W", perp=true, et="power", state_class="measurement", f="mean"},
    current = {u="A", perp=true, et="current", state_class="measurement", f="mean"},
    voltage = {u="V", perp=true, et="volt", state_class="measurement", f="mean"},
    temperature = {u="°C", perp=false, et="temp", state_class="measurement", f="mean"},
    -- Energy sux.  we have wh_in, per point onbars, and cumulative_wh, total, on meters....
    -- do we get silly and try looking for three phase breakers only? that's a bit of a risky hole...
    energy = {u="Wh", perp=false, et="cumulative_wh", state_class="total_increasing", f="max"}, -- FIXME wh_in as well? the gift that gives...
}

-- Many of these will be overridden (again) by the cli default args
local cfg_defaults = {
    APP_NAME = "output-hass",
    verbose = 5,
    mqtt_host = "localhost",
    ignore_model = false,
    MOSQ_CLIENT_ID = string.format("output-hass-%d", PU.getpid()),
    MOSQ_IDLE_LOOP_MS = 100,
    TOPIC_LISTEN_META = "status/local/json/cabinet/#",
}

--- Create a new application core.
-- @param opts any explicit command line options.  Will be merged with defaults
-- @param the statsd implementation desired.  this lets you replace it with fake implementations
function M.init(opts_in, statsd)
    local opts = opts_in or {}
    local finalopts = pl.tablex.union(cfg_defaults, opts)

    local x = uci.cursor(uci.get_confdir())
    x:foreach(finalopts.APP_NAME, "instance", function(s)
        if s[".name"] == opts.instance then
            finalopts.uci = s
        end
    end)
    if not finalopts.uci then
        error("can't start an instance without an instance config!")
    end
    if not finalopts.uci.mqtt_data_prefix then finalopts.uci.mqtt_data_prefix = "etactica" end

    -- gateway id
    local first = true
    x:foreach("system", "system", function(s)
        if first then
            first = false
            finalopts.uci.gateid = s.rme_stablemac
        end
    end)

    local i = {
        opts = finalopts,
        statsd = statsd,
        models = {},
    }
    setmetatable(i, M)
    ugly.initialize(i.opts.APP_NAME, i.opts.verbose) -- TODO instance?
    mosq.init()
    local mqtt = mosq.new(i.opts.MOSQ_CLIENT_ID, true)
    -- FIXME - we could / should do validation on illegal tls combos, we're only assuming user did the right thing here.
    if opts.mqtt_username and opts.mqtt_password then
        mqtt:login_set(opts.mqtt_username, opts.mqtt_password)
    end
    if opts.mqtt_psk and opts.mqtt_psk_id then
        mqtt:tls_psk_set(opts.mqtt_psk, opts.mqtt_psk_id)
    end
    if opts.mqtt_capath or opts.mqtt_cafile then
        mqtt:tls_set(opts.mqtt_cafile, opts.mqtt_capath, opts.mqtt_certfile, opts.mqtt_keyfile)
    end

    -- wat FIXME - this is gross...
    mqtt.ON_MESSAGE = function(mid, topic, jpayload, qos, retain)
        return i:mqtt_on_message(mid, topic, jpayload, qos, retain)
    end
    mqtt.ON_CONNECT = function(rc)
        return i:handle_on_connect(rc)
    end
    mqtt.ON_DISCONNECT = function(rc)
        if rc then
            ugly.notice("Disconnected cleanly. Odd, no code path does that.")
        else
            ugly.notice("MQTT connection lost, will attempt re-connecting")
        end
    end

    i.mqtt = mqtt
    ugly.info("Created a new application instance!")
    return i
end

function M:handle_on_connect(rc)
    ugly.debug("ok, got (re)connected: %s", tostring(rc))
    -- FIXME - if we're ignoring the model, I think we actually still need this, to get the hwids, we just change what we're using from it?
    if self.opts.ignore_model then
        ugly.notice("Cabinet model usage disabled, using hwid metric names only")
    else
        if not self.mqtt:subscribe(self.opts.TOPIC_LISTEN_META, 0) then
            ugly.err("Aborting, unable to subscribe to meta data stream")
            os.exit(1)
        end
    end
end

local expiry = {
    ["1min"] = 60*1.5,
    ["5min"] = 60*5*1.5,
    ["15min"] = 60*15*1.5,
    ["60min"] = 60*60*1.5,
}

function M:handle_live_meta(topic, payload)
    local cabinet = payload.cabinet
    if not cabinet then
        ugly.warning("No cabinet in cabinet model, ignoring on topic: %s", topic)
        self.statsd:increment("unexpected-format.nocabinet")
        return
    end
    local devid = payload.deviceid
    if not devid then
        ugly.warning("No deviceid in topic?! can't assign to cabinet model")
        self.statsd:increment("unexpected-format.nodevid")
        return
    end

    -- we keep no state, we just reformat and republish cabinet data as config data.
    local interval = self.opts.uci.interval
    for _, dt_key in pairs(self.opts.uci.store_types) do
        local dt = data_types[dt_key]
        if dt.perp then
            -- we have no idea whether a "branch" can produce what we want?!
            -- for energy, kinda safe, but this is goign to be a shitty integration for things that plugins can do...
            for _, b in pairs(payload.branches) do
                ugly.debug("Considering dtype: %s for dev:branch:%s:%s", dt_key, devid, b.label)
                -- make three sensors, and, if dtype is an aggregate, make up something fancy?
                for i,_ in ipairs(b.points) do
                    -- XXX, gateid or devid could create illegal hass uuids?
                    local uid = string.format("%s_%s_%s_%d", self.opts.uci.gateid, devid, dt_key, b.points[i].reading + 1)
                    local blob = {
                        device_class = dt_key,
                        name = string.format("%s_%s_%s_ph%d", cabinet, b.label, dt_key, b.points[i].phase),
                        state_topic = string.format("%s/status/interval/%s/%s/%s/%d",
                                self.opts.uci.mqtt_data_prefix, interval, devid, data_types[dt_key].et, b.points[i].reading + 1),
                        unit_of_measurement = data_types[dt_key].u,
                        value_template = string.format("{{ value_json.%s }}", data_types[dt_key].f),
                        unique_id = uid,
                        expire_after = expiry[interval],
                        -- model = FIXME -needs hwc,
                        -- manufacturer = FIXME -needs hwc,
                        via_device = self.opts.uci.gateid,
                        state_class = data_types[dt_key].state_class,
                    }
                    self.mqtt:publish(string.format("ext/output-hass/%s/discovery/sensor/%s/config", self.opts.instance, uid), json.encode(blob))
                    self.statsd:increment("sensor-config.published")
                end
            end
        else
            -- device level information, we don't even have cabinet model data for this, so we make it up...
            local uid = string.format("%s_%s_%s", self.opts.uci.gateid, devid, dt_key)
            local blob = {
                device_class = dt_key,
                name = string.format("%s_%s_%s", cabinet, devid, dt_key),
                state_topic = string.format("%s/status/interval/%s/%s/%s",
                        self.opts.uci.mqtt_data_prefix, interval, devid, data_types[dt_key].et),
                unit_of_measurement = data_types[dt_key].u,
                value_template = string.format("{{ value_json.%s }}", data_types[dt_key].f),
                unique_id = uid,
                expire_after = expiry[interval],
                -- model = FIXME -needs hwc,
                -- manufacturer = FIXME -needs hwc,
                via_device = self.opts.uci.gateid,
                state_class = data_types[dt_key].state_class,
            }
            self.mqtt:publish(string.format("ext/output-hass/%s/discovery/sensor/%s/config", self.opts.instance, uid), json.encode(blob))
            self.statsd:increment("sensor-config.published")
        end
    end
    ugly.info("Updated sensor config for all branches of device: %s", devid)

end

function M:mqtt_on_message(mid, topic, jpayload, qos, retain)
    ugly.debug("Got message: %s", topic)
    local payload, err = json.decode(jpayload)
    if not payload then
        ugly.notice("Ignoring non json message on topic: %s: %s", topic, err)
        self.statsd:increment("unexpected-format.notjson")
        return
    end
    self.statsd:meter("msgs-processed", 1)
    if mosq.topic_matches_sub(self.opts.TOPIC_LISTEN_META, topic) then
        return self:handle_live_meta(topic, payload)
    end
end

-- This app simply processes mqtt cabinet meta data and republishes it in hass style.
function M:run()
    self.mqtt:connect_async(self.opts.mqtt_host, self.opts.mqtt_port, 60)
    self.mqtt:loop_forever()
end

return M
