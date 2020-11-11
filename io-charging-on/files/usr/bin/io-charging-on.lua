#!/usr/bin/lua
--[[
    Karl Palsson, November 2020 <karlp@etactica.com>
]]

local json = require("cjson.safe")
-- cjson specific
json.encode_sparse_array(true)
local uci = require("uci")
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
    APP_NAME = "io-charging-on",
    MOSQ_CLIENT_ID = string.format("io-charging-on-%d", PU.getpid()),
    MOSQ_IDLE_LOOP_MS = 100,
    TOPIC_LISTEN_TEMPLATE = "status/local/json/device/%s/#",
}

local function timestamp_ms()
    local tspec = Pt.clock_gettime(Pt.CLOCK_REALTIME)
    return tspec.tv_sec * 1000 + math.floor(tspec.tv_nsec / 1e6)
end

-- Live variables, just kept in a table for sanity of access
local state = {
    sum_power = 0, -- Current running sum of power on all chargers.
}

ugly.initialize(cfg.APP_NAME, args.verbose or 4)

mosq.init()
local mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

if not mqtt:connect(args.mqtt_host, 1883, 60) then
    ugly.err("Aborting, unable to make MQTT connection")
    os.exit(1)
end

--- Validates the entries of a senml block, must have v, n, a time somewhere, etc
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

--- Validates the metadata (very rarely used) in a senml block
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

--- Handle periodic update of mains consumption information
--- As all devices are read in turn, each time we get a mains reading, we've (at least attempted to) read
--- all chargers as well.  Take all summed charging info since last time, and use that to generate the available
local function handle_mains(topic, payload)
    ugly.debug("Handle mains: %s", topic)
    -- NOTE, using the "sdevice" tree would be nice here! ;)
    -- Firstly, we have to scan the senml list to get all the per phase elements
    local power_phase = {{},{},{}}
    for _,e in pairs(payload.e) do
        for ph=1,3 do
            if e.n == string.format("volt/%d", ph) then power_phase[ph].v = e.v end
            if e.n == string.format("current/%d", ph) then power_phase[ph].i = e.v end
            if e.n == string.format("pf/%d", ph) then power_phase[ph].pf = e.v end
        end
    end
    ugly.warning("karl: %s", json.encode(power_phase))
    -- now we have total power used....
    local power_used = pl.tablex.reduce(function(a,b)
        return a + (b.v * b.i * b.pf)
    end, power_phase, 0)
    local aux_used = power_used - state.sum_power
    -- They are reporting this in _AMPS_ we need to get current power at current voltage, assuming pf1.0
    -- Common usage is that "size" of a breaker is 630A breaker has 630A on each phase.
    -- We're dynamically adjusting the "system max power" a bit based on current supply voltage.
    local cfg_max_power = pl.tablex.reduce(function(a,b)
        return a + (b.v * cfg.uci.mains_size)
    end, power_phase, 0)

    ugly.notice("configured max: %f, used now total: %f", cfg_max_power, power_used)
    ugly.notice("xxx: current charger sum used: %f, aux used :%f", state.sum_power, aux_used)
    local avail_to_chargers = cfg_max_power - aux_used
    ugly.notice("xxx: available to chargers = %f", avail_to_chargers)

    -- TODO - publish mqtt state information here?
    -- IMPORTANT! we've gotten a mains loop, reset the sum counters of chargers!
    local rv = {
        power_avail = avail_to_chargers,
        usage_total = power_used,
        usage_aux = aux_used,
        usage_chargers = state.sum_power,
        cfg_total_adj = cfg_max_power, -- configured total, adjusted for voltage
    }
    state.sum_power = 0
    return rv
end

--- Chargers just update usage provided.
local function handle_charger(topic, payload)
    local this_power = 0
    local this_state = 8
    for _,e in pairs(payload.senml.e) do
        if e.n == "power" then this_power = e.v end
        if e.n == "state" then this_state = e.v end
    end
    state.sum_power = state.sum_power + this_power

    local status_map = {
        "0-Available",
        "1-Preparing_TagId_Ready",
        "2-Preparing_EV_Ready",
        "3-Charging",
        "4-SuspendedEV",
        "5-SuspendedEVSE",
        "6-Finishing",
        "7-Reserved",
        "8-Unavailable",
        "9-UnavailableFwUpdate",
        "10-Faulted",
        "11-UnavailableConnObj",
    }
    ugly.debug("Handle charger: %s (%s): %f current power", payload.deviceid, status_map[this_state+1], this_power)

    return true
end

local function on_message_handler(mid, topic, jpayload, qos, retain)
    local payload, err, senml
    payload, err = json.decode(jpayload)
    if not payload then
        ugly.warning("Invalid json in message on topic: %s, %s", topic, err)
        return
    end
    if payload.hwc and payload.hwc.error then
        -- FIXME - might have to flag incomplete status loop?
        ugly.debug("ignoring error report: %s", topic)
        statsd:increment("read-error")
        return
    end
    senml, err = validate_senml(payload.senml)
    if not senml then
        ugly.warning("SenML block not found or invalid? %s", err)
    end
    statsd:meter("msgs-processed", 1)
    -- we're probably going to want to look at the whole state, to determine if we have a full set of data
    if mosq.topic_matches_sub(string.format(cfg.TOPIC_LISTEN_TEMPLATE, cfg.uci.mains_id), topic) then
        -- Save it to a queue to work on outside message handler context.
        state.work_item = handle_mains(topic, senml)
    else
        handle_charger(topic, payload)
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
        local err2 = string.format("Lost MQTT connection: %d %s", errno, err)
        ugly.crit(err2)
        error(err2)
    end
    mqtt_idle_timer:set(cfg.MOSQ_IDLE_LOOP_MS)
end, cfg.MOSQ_IDLE_LOOP_MS)

local function load_config()
    local x = uci.cursor(uci.get_confdir())
    x:foreach(cfg.APP_NAME, "general", function(s)
        if cfg.uci then
            error("Duplicate 'general' section in uci config!")
        end
        cfg.uci = s
    end)
    -- FIXME - definitely need more modbus connection details here....
end

load_config()
mqtt.ON_MESSAGE = on_message_handler
ugly.debug("running with cfg: %s", pl.pretty.write(cfg))
for _,v in pairs(cfg.uci.charger_ids) do
    ugly.debug("Subscribing to charger id: %s", v)
    local ok, err = mqtt:subscribe(string.format(cfg.TOPIC_LISTEN_TEMPLATE, v), 0)
    if not ok then error("Failed to subscribe to charger topic: " .. err) end
end

local ok, err = mqtt:subscribe(string.format(cfg.TOPIC_LISTEN_TEMPLATE, cfg.uci.mains_id), 0)
if not ok then error("Failed to subscribe to mains topic: " .. err) end



uloop.run()
