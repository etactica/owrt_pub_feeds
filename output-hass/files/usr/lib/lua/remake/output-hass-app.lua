--[[
The functional portion of the output-hass application.
Karl Palsson, Nov 2021 <karlp@tweak.net.au>

--]]

local json = require("cjson.safe")
-- cjson specific
json.encode_sparse_array(true)
local mosq = require("mosquitto") -- only used for topic matching.
local pl = require("pl.import_into")()
local PU = require("posix.unistd")
local ugly = require("remake.uglylog")

local M = {}
M.__index = M

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

    -- if there is an existing cabinet model for this device, just _replace_ it wholesale.
    self.models[devid] = {cabinet = cabinet, branches = {}}
    -- just keep the original branches, with a cabinet pointer on each one
    for _, b in pairs(payload.branches) do
        b.cabinet = cabinet
        table.insert(self.models[devid].branches, b)
    end
    --ugly.debug("Saved internal cabinet model of %s: %s", devid, pl.pretty.write(self.models[devid]))

    -- FIXME - actually implement this!
    -- need to reformat into as many pieces as required of hass style config messages, publish back to ourself, and let the mqtt bridge mapping take care of the rest.

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
