#!/usr/bin/lua
--[[
    Karl Palsson, 2019 <karlp@remake.is>
]]

local json = require("cjson.safe")
-- cjson specific
json.encode_sparse_array(true)
local uloop = require("uloop")
uloop.init()
local mosq = require("mosquitto")
local PU = require("posix.unistd")
local Pt = require("posix.time")
local ugly = require("remake.uglylog")

local pl = require("pl.import_into")()
local args = pl.lapp [[
    -H,--mqtt_host (default "localhost") MQTT host to listen to
    -v,--verbose (0..7 default 4) Logging level, higher == more
    -S,--statsd_host (default "localhost") StatsD server address
    --statsd_port (default 8125) StatsD port
    --statsd_namespace (default "live") Namespace for this data
]]

local statsd = require("statsd")({
    namespace = args.statsd_namespace,
    host = args.statsd_host,
    port = args.statsd_port,
})

local cfg = {
    APP_NAME = "output-statsd",
    MOSQ_CLIENT_ID = string.format("output-statsd-%d", PU.getpid()),
    MOSQ_IDLE_LOOP_MS = 100,
    TOPIC_LISTEN_DATA = "status/local/json/device/#",
}

local function timestamp_ms()
    local tspec = Pt.clock_gettime(Pt.CLOCK_REALTIME)
    return tspec.tv_sec * 1000 + math.floor(tspec.tv_nsec / 1e6)
end

-- Live variables, just kept in a table for sanity of access
local state = {

}

ugly.initialize(cfg.APP_NAME, args.verbose or 4)

mosq.init()
local mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

if not mqtt:connect(args.mqtt_host, 1883, 60) then
    ugly.err("Aborting, unable to make MQTT connection")
    os.exit(1)
end

if not mqtt:subscribe(cfg.TOPIC_LISTEN_DATA, 0) then
    ugly.err("Aborting, unable to subscribe to live data stream")
    os.exit(1)
end


local function validate_entries(eee, bt)
    local rval = true
    for k,e in pairs(eee) do
        if type(e) ~= "table" then rval = false; break end

        if not e.v then rval = false; break end
        if type(e.v) ~= "number" then rval = false; break end

        if not e.n then rval = false; break end
        if type(e.n) ~= "string" then rval = false; break end

        if e.u and type(e.u) ~= "string" then rval = false; break end

        if e.t and type(e.t) ~= "number" then rval = false; break end
        if not e.t and not bt then rval = false; break; end
        -- safe to modify here, it wasn't provided, so it will have no affect
        if not e.t then e.t = 0 end
    end
    return rval
end

-- will modify meta if necessary!
local function validate_meta(eee)
    if eee.bn and type(eee.bn) ~= "string" then return false end
    -- safe to modify, not required, but need string concat to work
    if not eee.bn then eee.bn = "" end

    if eee.bt and type(eee.bt) ~= "number" then return false end
    return true
end

local function validate_senml(senml)
    if type(senml) ~= "table" then return nil, "Input wasn't a table" end
    if type(senml.e) ~= "table" then return nil, "Senml Entries 'e' wasn't a table" end
    if not validate_meta(senml) then return nil, "Metadata (bt,bn etc) were invalid" end
    if not validate_entries(senml.e, senml.bt) then return nil, "Some entries were invalid, ignoring batch" end
    if not senml.bt then senml.bt = 0 end
    return senml
end

--- Take a senml blob, and updates everything necessary for delta processing
-- Does validation on the input data
-- @param senml_in a table of senml.
-- @return[1] nil if the senml failed validation.
-- @return[1] errmsg why it failed validation
-- @return[2] true normal case.
local function add_senml(senml_in)
    local senml, err = validate_senml(senml_in)
    if not senml then return nil, err end
    for _,e in pairs(senml.e) do
        local fulln = senml.bn .. e.n
        --local fullt = senml.bt + e.t
        ugly.debug("Adding gauge for %s with v %f", fulln, e.v)
        statsd:gauge(fulln, e.v)
    end
    return true
end

local function handle_senml(topic, jpayload)
    local payload, err = json.decode(jpayload)
    if not payload then
        ugly.warning("Invalid json in message on topic: %s, %s", topic, err)
        return
    end
    statsd:meter("senml-input", 1)
    if payload.hwc and payload.hwc.error then
        ugly.debug("ignoring error report: %s", topic)
        statsd:increment("read-error")
        return
    end
    if not payload.senml then
        ugly.debug("Ignoring non-senml report: %s", topic)
        statsd:increment("non-senml")
        return
    end
    local rval, msg = add_senml(payload.senml)
    if not rval then ugly.warning("Failed to process senml: %s", msg) end
end


mqtt.ON_MESSAGE = function(mid, topic, jpayload, qos, retain)
    if mosq.topic_matches_sub(cfg.TOPIC_LISTEN_DATA, topic) then
        return handle_senml(topic, jpayload)
    end
end

local mqtt_read = uloop.fd_add(mqtt:socket(), function(ufd, events)
    mqtt:loop_read()
end, uloop.ULOOP_READ)

local mqtt_write = uloop.fd_add(mqtt:socket(), function(ufd, events)
    mqtt:loop_write()
end, uloop.ULOOP_WRITE)

local mqtt_idle_timer
mqtt_idle_timer = uloop.timer(function()
    -- just handle the mosquitto idle/misc loop
    local success, errno, err = mqtt:loop_misc()
    if not success then
        local err = string.format("Lost MQTT connection: %s", err)
        ugly.crit(err)
        error(err)
    end
    mqtt_idle_timer:set(cfg.MOSQ_IDLE_LOOP_MS)
end, cfg.MOSQ_IDLE_LOOP_MS)

uloop.run()
