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
    -I,--ignore_model Ignore the cabinet model.
        By default, we attempt to create metrics based on the cabinet model
        This does mean that if you edit your model, your metrics will change,
        but that was probably what you wanted anyway!
        With this flag, the cabinet model will be ignored, and metrics will be
        published using the fallback hardware identifiers (deviceid.metric.channel)
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
    TOPIC_LISTEN_DATA = "status/local/json/sdevice/#",
    TOPIC_LISTEN_META = "status/local/json/cabinet/#",
}

local function timestamp_ms()
    local tspec = Pt.clock_gettime(Pt.CLOCK_REALTIME)
    return tspec.tv_sec * 1000 + math.floor(tspec.tv_nsec / 1e6)
end

-- Live variables, just kept in a table for sanity of access
local state = {
    cabinet_model = {},
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

if args.ignore_model then
    ugly.notice("Cabinet model usage disabled, using hwid metric names only")
else
    if not mqtt:subscribe(cfg.TOPIC_LISTEN_META, 0) then
        ugly.err("Aborting, unable to subscribe to meta data stream")
        os.exit(1)
    end
end


--- Take a set of live readings of "simple data" and makes appropriate statsd metrics
-- @param "simple data" json form
-- @return[1] true normal case.
local function add_live_data(data)
    for k,v in pairs(data.readings) do
        local fulln = string.format("%s/%s", data.deviceid, k)
        -- translate MQTT '/' separated topic levels into statsd '.' separated
        fulln = fulln:gsub("/", ".")
        ugly.debug("Adding gauge for %s with v %f", fulln, v)
        statsd:gauge(fulln, v)
    end
    return true
end

local function handle_live_data(topic, payload)
    if payload.hwc and payload.hwc.error then
        ugly.debug("ignoring error report: %s", topic)
        statsd:increment("read-error")
        statsd:increment("read-error." .. payload.hwc.deviceid)
        return
    end
    if not payload.readings then
        ugly.debug("no error, but no readings? very unexpected data! %s", topic)
        statsd:increment("unexpected-format.noreadings")
        return
    end
    local rval, msg = add_live_data(payload)
    if not rval then ugly.warning("Failed to process readings: %s", msg) end
end

local function handle_live_meta(topic, payload)
    local cabinet = payload.cabinet
    if not cabinet then
        ugly.warning("No cabinet in cabinet model, ignoring on topic: %s", topic)
        statsd:increment("unexpected-format.nocabinet")
        return
    end
    local devid = payload.deviceid
    if not devid then
        ugly.warning("No deviceid in topic?! can't assign to cabinet model")
        statsd:increment("unexpected-format.nodevid")
        return
    end

    -- if there is an existing cabinet model for this device, just _replace_ it wholesale.
    state.cabinet_model[devid] = {}
    -- just keep the original branches, with a cabinet pointer on each one
    for _, b in pairs(payload.branches) do
        b.cabinet = cabinet
        table.insert(state.cabinet_model[devid], b)
    end
    ugly.debug("Saved internal cabinet model of %s", pl.pretty.write(state.cabinet_model[devid]))

end

mqtt.ON_MESSAGE = function(mid, topic, jpayload, qos, retain)
    local payload, err = json.decode(jpayload)
    if not payload then
        ugly.notice("Ignoring non json message on topic: %s: %s", topic, err)
        statsd:increment("unexpected-format.notjson")
        return
    end
    statsd:meter("msgs-processed", 1)
    if mosq.topic_matches_sub(cfg.TOPIC_LISTEN_META, topic) then
        return handle_live_meta(topic, payload)
    end

    if mosq.topic_matches_sub(cfg.TOPIC_LISTEN_DATA, topic) then
        return handle_live_data(topic, payload)
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
