--[[
The functional portion of the output-statsd application.
Karl Palsson, Nov 2020 <karlp@etactica.com>

TODO: make the "metric name" construction all contained in one place,
      using a template language, so it can be configured?
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
    APP_NAME = "output-statsd",
    verbose = 5,
    mqtt_host = "localhost",
    ignore_model = false,
    MOSQ_CLIENT_ID = string.format("output-statsd-%d", PU.getpid()),
    MOSQ_IDLE_LOOP_MS = 100,
    TOPIC_LISTEN_DATA = "status/local/json/sdevice/#",
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
    ugly.initialize(i.opts.APP_NAME, i.opts.verbose)
    mosq.init()
    local mqtt = mosq.new(i.opts.MOSQ_CLIENT_ID, true)

    mqtt.ON_MESSAGE = function(mid, topic, jpayload, qos, retain)
        return i:mqtt_on_message(mid, topic, jpayload, qos, retain)
    end
    i.mqtt = mqtt
    return i
end

--- Connect and subscribe
-- TODO - make this return errors, rather than calling os.exit() ?
function M:connect()

    if not self.mqtt:connect(self.opts.mqtt_host, 1883, 60) then
        ugly.err("Aborting, unable to make MQTT connection")
        os.exit(1)
    end

    if not self.mqtt:subscribe(self.opts.TOPIC_LISTEN_DATA, 0) then
        ugly.err("Aborting, unable to subscribe to live data stream")
        os.exit(1)
    end

    if self.opts.ignore_model then
        ugly.notice("Cabinet model usage disabled, using hwid metric names only")
    else
        if not self.mqtt:subscribe(self.opts.TOPIC_LISTEN_META, 0) then
            ugly.err("Aborting, unable to subscribe to meta data stream")
            os.exit(1)
        end
    end

end

--- Adds a full live data set, based on eTactica "sdevice" format
function M:add_live_data(data)
    local model_null = { branches= {}}
    local model_real = self.models[data.deviceid]
    local model = model_real or model_null

    -- ok we have a cabinet model for this device, lets
    -- look for everything we understand in the live reading, and cross it off first...
    -- a 12 pin bar here might have 4 points, each with
    for _,branch in pairs(model.branches) do
        local ampsize = branch.ampsize
        local label = branch.label
        -- if label has . in it, replace with _ to not create submetrics unintentionally
        label = label:gsub("%.", "_")
        local cabname = branch.cabinet
        local cum_vars = {}
        for _,p in pairs(branch.points) do
            -- handle anything we know we can just handle outright per phase one by one.
            local perphase = {"current", "volt", "pf", "power"}
            for _,type in pairs(perphase) do
                local key = string.format("%s/%d", type, p.reading + 1)
                if data.readings[key] then
                    -- for current, no need to read all three, as we can just send them one by one..
                    local fulln = string.format("%s.%s.%s.%d", cabname, label, type, p.phase)
                    ugly.debug("Adding gauge for %s with v %f", fulln, data.readings[key])
                    self.statsd:gauge(fulln, data.readings[key])
                    -- and, importantly, delete it from the incoming data, so we can process "remainders" later
                    -- only do this if you know you are done!
                    -- If you want to provide avg/aggr, it's arguably easier to do them here, than in server side
                    data.readings[key] = nil
                end
            end
            -- need to perhaps sum per phase wh_in here...
            local key = string.format("wh_in/%d", p.reading + 1)
            if data.readings[key] then
                if not cum_vars.cumulative_wh then cum_vars.cumulative_wh = 0 end
                cum_vars.cumulative_wh = cum_vars.cumulative_wh + data.readings[key]
                data.readings[key] = nil
            end
        end
        for _,k in pairs({"cumulative_wh", "cumulative_varh", "power_sum"}) do
            if not cum_vars[k] then
                -- try and see if we have it directly, as we would from a meter type device
                cum_vars[k] = data.readings[k]
                data.readings[k] = nil
            end
            if cum_vars[k] then
                local fulln = string.format("%s.%s.%s", cabname, label, k)
                ugly.debug("Adding gauge for %s with v %f", fulln, cum_vars[k])
                self.statsd:gauge(fulln, cum_vars[k])
            end
        end
    end

    -- remaining points are un-modeled as "branches" but we might still have a cabinet for this device.
    local prefix = ""
    if model.cabinet then
        prefix = model.cabinet .. "."
    end
    -- if we have a cabinet for this device, use th
    -- Handle un-modeled fields as fallbackk
    for k,v in pairs(data.readings) do
        local fulln = string.format("%s%s.%s", prefix, data.deviceid, k)
        -- translate MQTT '/' separated topic levels into statsd '.' separated
        fulln = fulln:gsub("/", ".")
        ugly.debug("Adding gauge for %s with v %f", fulln, v)
        self.statsd:gauge(fulln, v)
    end

    return true
end

function M:handle_live_data(topic, payload)
    if payload.hwc and payload.hwc.error then
        ugly.debug("ignoring error report: %s", topic)
        self.statsd:increment("read-error")
        local did = "unknown"
        if payload.hwc.deviceid then did = payload.hwc.deviceid end
        self.statsd:increment("read-error." .. did)
        return
    end
    if not payload.readings then
        ugly.debug("no error, but no readings? very unexpected data! %s", topic)
        self.statsd:increment("unexpected-format.noreadings")
        return
    end
    --local rval, msg = add_live_data(payload)
    local rval, msg = self:add_live_data(payload)
    if not rval then ugly.warning("Failed to process readings: %s", msg) end
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
    ugly.debug("Saved internal cabinet model of %s: %s", devid, pl.pretty.write(self.models[devid]))

end

function M:mqtt_on_message(mid, topic, jpayload, qos, retain)
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

    if mosq.topic_matches_sub(self.opts.TOPIC_LISTEN_DATA, topic) then
        return self:handle_live_data(topic, payload)
    end

end


return M
