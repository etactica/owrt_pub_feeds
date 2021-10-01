--[[
The core of the io-charging-on app.  Allows testing individual methods, but is not
planned or tested as a repeatedly importable "app" module as some lua modules do.
It's more a singleton, in that it uses scope local configs....
Karl Palsson <karlp@etactica.com> Nov 2020 (this incarnation)
--]]

local json = require("cjson.safe")
local uci = require("uci")
local ugly = require("remake.uglylog")
local uloop = require("uloop")
local mb = require("libmodbus")
local mosq = require("mosquitto")
local PU = require("posix.unistd")
local Pt = require("posix.time")

local pl = require("pl.import_into")()

local _APP_NAME = "io-charging-on"
local cfg = {
    APP_NAME = _APP_NAME,
    MOSQ_CLIENT_ID = string.format("io-charging-on-%d", PU.getpid()),
    MOSQ_IDLE_LOOP_MS = 100,
    APP_MAIN_LOOP_MS = 500,
    MAX_CHARGER_AGE_MS = 6000, -- ~three successive failures, in normal config, unlikely to need to change this
    TOPIC_LISTEN_TEMPLATE = "status/local/json/device/%s/#",
    TOPIC_APP_STATE = "status/local/json/applications/" .. _APP_NAME .. "/state",
}

-- "globals" that a few people need direct access to (we're not making an object just to hold them)
local statsd

-- Live variables, just kept in a table for sanity of access
local state = {
    chargers = {},
}

local function timestamp_ms()
    local tspec = Pt.clock_gettime(Pt.CLOCK_REALTIME)
    return tspec.tv_sec * 1000 + math.floor(tspec.tv_nsec / 1e6)
end

local ChargerBase = {}
ChargerBase.__index = ChargerBase

setmetatable(ChargerBase, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_create(...)
        return self
    end
})

function ChargerBase:_create(serial, mbunit, mbaddress, mbservice)
    self.serial = serial
    self.mbunit = mbunit
    self.mbaddress = mbaddress
    self.mbservice = mbservice

    local err
    self.dev, err = mb.new_tcp_pi(mbaddress, mbservice)
    if not self.dev then
        -- This is a rather fatal type of error, can't even create a modbus context.
        error("Couldn't create a modbus client context: " .. err)
    end
    -- "fast" We're using modbus/tcp, on LAN, if it's more than 200ms, we already have problems.
    self.dev:set_response_timeout(0, 200 * 1000)
end

function ChargerBase:set_available_power(power)
    error("must be implemented by derived classes")
end

--- Return the new allowed power we should assign to this charger.
-- @tparam number power_avail_chargers power total to be allocated to chargers now
-- @tparam number power_used_chargers power total currently consumed by all chargers
-- @treturn number what new value to assign to _this_ charger.
function ChargerBase:calculate_allowed_power(power_avail_chargers, power_used_chargers)
    local delta = power_avail_chargers - power_used_chargers
    if delta >= 0 then
        -- undersubscribed, keep what _we're_ using, plus the difference up to the cap.
        return delta + self.power
    else
        -- oversubscribed, need to shed from all equally.
        return self.power + delta * (self.power / power_used_chargers)
    end
end

--- Return the power used by this charger, if valid, else 0.
-- @tparam number ts the timestamp in milliseconds now
-- @treturn number 0 if reading is too old
-- @treturn number the last reported power if fresh
function ChargerBase:valid_power(ts_ms)
    local this_charger = 0
    if ts_ms - self.ts < cfg.MAX_CHARGER_AGE_MS then
        this_charger = self.power
    end
    return this_charger
end

function ChargerBase:update(ts_ms, power, state)
    self.power = power
    self.state = state
    self.ts = ts_ms
    ugly.debug("Handle charger: %s (%s): %f current power", self.serial, self.state, self.power)
    statsd:gauge("chargers." .. self.serial .. ".power", self.power)

end

local AlpitronicHypercharger = {}
AlpitronicHypercharger.__index = AlpitronicHypercharger

setmetatable(AlpitronicHypercharger, {
    __index = ChargerBase,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_create(...)
        return self
    end
})

-- we don't actually need this at the moment...
function AlpitronicHypercharger:_create(serial, mbunit, mbaddress, mbservice)
    ChargerBase._create(self, serial, mbunit, mbaddress, mbservice)
    -- fake demo blah.
    self._extra = 123
end

function AlpitronicHypercharger:__tostring()
    return string.format("AlpitronicHypercharger<%s, %d(%#x) @ %s:%s>", self.serial, self.mbunit, self.mbunit, self.mbaddress, tostring(self.mbservice))
end

--- Set the available power on a charger.
-- We reconnect every time, as the charger docs expliciltly note that it must
-- be reconnected if it ever loses connections.
-- It's always tcp, so, just connect every time?  At least for now...
-- we can later try and disconnect/connect on demand....
-- @tparam number power in watts to make available to the charger.
-- @return true, or nil if it failed to write.  Callee can retry, report, or wait til next write.
-- @return nil, or error message
function AlpitronicHypercharger:set_available_power(power)
    local pre = timestamp_ms()
    local function real()
        local ok, err = self.dev:connect()
        if not ok then return nil, err end
        self.dev:set_slave(self.mbunit)

        local regs = {mb.set_s32(power)}
        ok, err = self.dev:write_registers(0, regs)
        -- close no matter what, to not leak fds, and nothing we can do if it fails anywhere
        self.dev:close()
        return ok, err
    end
    local ok, err = real()
    -- TODO - stringformat on every action is... not a great use of cpu power.
    statsd:timer(string.format("chargers.%s.set-power", self.serial), timestamp_ms() - pre)
    return ok, err
end



local function do_init(args)
    -- cjson specific
    json.encode_sparse_array(true)
    mosq.init()
    uloop.init()

    args = args or {}
    --cfg = default_cfg
    cfg.args = args
    ugly.initialize(cfg.APP_NAME, args.verbose or 4)

    --cfg = cfg_validate(cfg)

    local stub_statsd = {
        counter = function() end,
        decrement = function() end,
        gauge = function() end,
        histogram = function() end,
        increment = function() end,
        meter = function() end,
        timer = function() end,
    }
    statsd = stub_statsd
    local has_statsd, statsdmodule = pcall(require, "statsd")
    if has_statsd then
        ugly.debug("statsd module available, enabling.")
        statsd = statsdmodule({
            namespace = args.statsd_namespace,
            host = args.statsd_host,
            port = args.statsd_port,
        })
    end
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
    if payload.hwc and payload.hwc.error then
        statsd:increment("mains." .. payload.hwc.deviceid .. ".read-failure")
        return
    end
    -- NOTE, using the "sdevice" tree would be nice here! ;)
    -- Firstly, we have to scan the senml list to get all the per phase elements
    local power_phase = {{},{},{}}
    for _,e in pairs(payload.senml.e) do
        for ph=1,3 do
            if e.n == string.format("volt/%d", ph) then power_phase[ph].v = e.v end
            if e.n == string.format("current/%d", ph) then power_phase[ph].i = e.v end
            if e.n == string.format("pf/%d", ph) then power_phase[ph].pf = e.v end
        end
    end
    -- now we have total power used....
    local power_used_total = pl.tablex.reduce(function(a,b)
        return a + (b.v * b.i * b.pf)
    end, power_phase, 0)

    -- Sum the reported usage of chargers, but only the ones that we have, and only if they're up to date.
    local ts_now = timestamp_ms()
    local power_used_chargers = pl.tablex.reduce(function(a,b)
        return a + b:valid_power(ts_now)
    end, pl.tablex.values(state.chargers), 0)

    -- auxilliary is always just total less chargers, nice and simple...
    local power_used_aux = power_used_total - power_used_chargers

    -- They are configuring this in _AMPS_ we need to get current power at current voltage, assuming pf1.0
    -- Common usage is that "size" of a breaker is 630A breaker has 630A on each phase.
    -- We're dynamically adjusting the "system max power" a bit based on current supply voltage.
    local power_cfg_max = pl.tablex.reduce(function(a, b)
        return a + (b.v * cfg.uci.mains_size)
    end, power_phase, 0)

    local power_avail_chargers = power_cfg_max - power_used_aux
    ugly.notice("mains: %s, max allowed: %.1f kW, usage (total): %.1f kW, avail to chargers: %.1f kW", payload.deviceid, power_cfg_max /1000, power_used_total/1000, power_avail_chargers /1000)
    ugly.debug("xxx: current charger sum used: %f, aux used :%f", power_used_chargers, power_used_aux)

    local rv = {
        power_avail_chargers = power_avail_chargers,
        power_used_total = power_used_total,
        power_used_aux = power_used_aux,
        power_used_chargers = power_used_chargers,
        power_cfg_max = power_cfg_max, -- configured total, adjusted for voltage
    }
    return rv
end

--- Chargers just update usage provided.
local function handle_charger(topic, payload)
    if payload.hwc and payload.hwc.error then
        statsd:increment("chargers." .. payload.hwc.deviceid .. ".read-failure")
        return
    end
    local this_power = 0
    local this_state = 8
    for _,e in pairs(payload.senml.e) do
        if e.n == "power" then this_power = e.v end
        if e.n == "state" then this_state = e.v end
    end
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
    this_state = status_map[this_state+1]
    local charger = state.chargers[payload.deviceid]
    if not charger then
        -- first time we've seen this charger, fetch it's modbus info and create a helper object
        local unitid = payload.hwc.slaveId
        local mbdev = payload.hwc.mbDevice
        local mbc = cfg.mbc[mbdev]
        if not mbc then
            -- This _should_ only happen with fake devices, on the implicit "local" connection
            if mbdev == "local" then
                mbc = {address = "localhost", service = "1502"}
            else
                error("Charger has no Modbus connection information! Application error!")
            end
        end
        -- TODO - make different ones if we like....
        charger = AlpitronicHypercharger(payload.deviceid, unitid, mbc.address, mbc.service)
        ugly.notice("Created new charger: %s", tostring(charger))
        state.chargers[charger.serial] = charger
    end
    charger:update(payload.timestamp_ms, this_power, this_state)

    return true
end

local function on_message_handler(mid, topic, jpayload, qos, retain)
    local payload, err
    payload, err = json.decode(jpayload)
    if not payload then
        ugly.warning("Invalid json in message on topic: %s, %s", topic, err)
        return
    end
    -- this will modify the senml block if necessary to handle bn/n and bt/t joining
    validate_senml(payload.senml)
    statsd:meter("msgs-processed", 1)
    if mosq.topic_matches_sub(string.format(cfg.TOPIC_LISTEN_TEMPLATE, cfg.uci.mains_id), topic) then
        -- Save it to a queue to work on outside message handler context.
        state.work_item = handle_mains(topic, payload)
    else
        handle_charger(topic, payload)
    end
end


local function load_config()
    local x = uci.cursor(uci.get_confdir())
    x:foreach(cfg.APP_NAME, "general", function(s)
        if cfg.uci then
            error("Duplicate 'general' section in uci config!")
        end
        cfg.uci = s
    end)
    -- We also need to load mlifter modbus connection config, for remote devices
    cfg.mbc = {}
    x:foreach("mlifter", "device", function(s)
        cfg.mbc[s['.name']] = s
    end)
    -- We can't create any "charger" devices here, as we need to get some live data
    -- to correlate with the modbus information
end

local function do_main()
    load_config()
    ugly.debug("running with cfg: %s", pl.pretty.write(cfg))
    if not cfg.uci.charger_ids or #cfg.uci.charger_ids == 0 then
        ugly.notice("No chargers to monitor, exiting.")
        os.exit(0)
    end
    if not cfg.uci.mains_id then
        ugly.notice("No mains to monitor, exiting.")
        os.exit(0)
    end

    local mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

    mqtt:will_set(cfg.TOPIC_APP_STATE, nil, 1, true)
    if not mqtt:connect(cfg.args.mqtt_host, 1883, 60) then
        ugly.err("Aborting, unable to make MQTT connection")
        os.exit(1)
    end

    -- MQTT BOILER PLATE (abort version) -----
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
    -- END MQTT BOILER PLATE -----

    local app_main_timer
    app_main_timer = uloop.timer(function()

        -- do main loop... write work item to chargers
        if state.work_item then
            mqtt:publish(cfg.TOPIC_APP_STATE, json.encode(state.work_item), 1, true)
            -- Publish all of it as gauges of inner health.
            for k,v in pairs(state.work_item) do statsd:gauge(k, v) end
            for _,charger in pairs(state.chargers) do
                local new_power = charger:calculate_allowed_power(state.work_item.power_avail_chargers, state.work_item.power_used_chargers)
                ugly.debug("Writing avail: %f to charger: %s", new_power, tostring(charger))
                local ok, err = charger:set_available_power(new_power)
                if not ok then
                    -- that's all we need though, we'll just retry next time, it's about all we _can_ do.
                    ugly.warning("Failed to set available power (%f W) on charger: %s: %s",
                            state.work_item.power_avail_chargers, tostring(charger), err)
                    statsd:increment("chargers." .. charger.serial .. ".write-failure")
                end
            end
            state.work_item = nil
        end

        app_main_timer:set(cfg.APP_MAIN_LOOP_MS)
    end, cfg.APP_MAIN_LOOP_MS)


    mqtt.ON_MESSAGE = on_message_handler
    for _,v in pairs(cfg.uci.charger_ids) do
        ugly.debug("Subscribing to charger id: %s", v)
        local ok, err = mqtt:subscribe(string.format(cfg.TOPIC_LISTEN_TEMPLATE, v), 0)
        if not ok then error("Failed to subscribe to charger topic: " .. err) end
    end

    local ok, err = mqtt:subscribe(string.format(cfg.TOPIC_LISTEN_TEMPLATE, cfg.uci.mains_id), 0)
    if not ok then error("Failed to subscribe to mains topic: " .. err) end

    uloop.run()

end

local M = {
    init = do_init,
    main = do_main,
}

return M
