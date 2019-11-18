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
local uci = require("uci")
local ugly = require("remake.uglylog")

local pl = require("pl.import_into")()
local args = pl.lapp [[
    -H,--mqtt_host (default "localhost") MQTT host to listen to
    -v,--verbose (0..7 default 4) Logging level, higher == more
    -i,--instance (string) UCI service instance to run

    "All" configuration is loaded from the UCI file for the given instance
]]

-- Default global configuration
local cfg = {
    APP_NAME = "output-db",
    MOSQ_CLIENT_ID = string.format("output-db-%s-%d", args.instance, PU.getpid()),
    MOSQ_IDLE_LOOP_MS = 500,
    DEFAULT_STORE_TYPES = {"cumulative_wh"},
    -- We're going to listen to more than we theoretically need to, but we can just drop it
    DEFAULT_TOPIC_DATA = "status/+/json/interval/%dmin/#",
    DEFAULT_TOPIC_METADATA = "status/+/json/cabinet/#",
    DEFAULT_INTERVAL = 15, -- in minutes
    DATABASE_VERSION = 1,
    PATH_SCHEMA = "/usr/share/output-db"
}
ugly.initialize(cfg.APP_NAME, args.verbose or 4)

-- Read instance configuration and merge
local x = uci.cursor()
x:foreach(cfg.APP_NAME, "instance", function(s)
    if s[".name"] ~= args.instance then return end
    ugly.debug("found our instance config? %s", pl.pretty.write(s))
    cfg.uci = s
end)

-- checks and fills in defaults
-- raises if required fields are not available
local function cfg_validate(c)
    c.interval = c.uci.interval or cfg.DEFAULT_INTERVAL
    c.topic_data_in = string.format(cfg.DEFAULT_TOPIC_DATA, c.interval)
    c.topic_metadata_in = cfg.DEFAULT_TOPIC_METADATA
    c.store_types = c.uci.store_types or cfg.DEFAULT_STORE_TYPES
    return c
end

cfg = cfg_validate(cfg)
ugly.notice("Starting operations with config: %s", pl.pretty.write(cfg))

local function timestamp_ms()
    local tspec = Pt.clock_gettime(Pt.CLOCK_REALTIME)
    return tspec.tv_sec * 1000 + math.floor(tspec.tv_nsec / 1e6)
end

-- Live variables, just kept in a table for sanity of access
local state = {

}

local function db_connect()
    local dname = string.format("luasql.%s", cfg.uci.driver)
    local driver = require (dname)
    if not driver then error("Couldn't load driver for: " .. dname) end
    local env = driver[cfg.uci.driver]()
    if not env then error("Couldn't open environment for driver") end
    local params = {cfg.uci.dbname, cfg.uci.dbuser, cfg.uci.dbpass, cfg.uci.dbhost}
    if cfg.uci.dbport then table.insert(params, cfg.uci.dbport) end
    local conn, err = env:connect(table.unpack(params))
    if not conn then
        error(string.format("Couldn't connect with %s: %s", pl.pretty.write(params), err))
    end
    return conn
end

local conn = db_connect()

local function db_validate_schema(conn, driver)
    -- Load the schema for this driver
    -- This is convoluted, because mysql doesn't let you run multiple statements in one go.
    local schemas, ferr = pl.dir.getfiles(cfg.PATH_SCHEMA, string.format("schema.%s.*.sql", driver))
    if not schemas then error(string.format("Couldn't load schema(s) for driver: %s: %s", driver, ferr)) end

    -- Creates tables if they don't exist.
    for _,fn in ipairs(schemas) do
        local schema, serr = pl.file.read(fn)
        if not schema then error(string.format("Failed to read schema file: %s: %s", fn, serr)) end
        local rows, err = conn:execute(schema)
        if not rows then
            error("Failed to update schema: " .. err)
        else
            print("update schema returned", rows)
        end
    end

    local q = [[select val from metadata where mkey = 'version']]
    local cur = conn:execute(q)
    if not cur then error("Couldn't execute the version check") end
    local row = cur:fetch({}, "a")
    local version
    while row do
        version = tonumber(row.val)
        row = cur:fetch (row, "a")
    end

    if version then
        if version < cfg.DATABASE_VERSION then
            -- TODO Here should be a function to deal with the old database.
            error("No Function to deal with different database version")
        end
        ugly.debug("Database running version: %d", version)
    else
        local rows, err = conn:execute(string.format([[insert into metadata (mkey, val) values ('version', '%d')]], cfg.DATABASE_VERSION))
        if not rows then
            print("setting version failed: ", err)
            error("failed to set version")
        end
    end
end

db_validate_schema(conn, cfg.uci.driver)

mosq.init()
local mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

if not mqtt:connect(args.mqtt_host, 1883, 60) then
    ugly.err("Aborting, unable to make MQTT connection")
    os.exit(1)
end

if not mqtt:subscribe(cfg.topic_data_in, 0) then
    ugly.err("Aborting, unable to subscribe to live data stream")
    os.exit(1)
end

-- Make a unique key for a datapoint
-- This makes a key that is == the trailer of the mqtt topic,
local function make_key(device, datatype, channel)
    if channel then
        return string.format("%s/%s/%s", device, datatype, channel)
    else
        return string.format("%s/%s", device, datatype)
    end
end

local function handle_interval_data(topic, jpayload)
    local segs = pl.stringx.split(topic, "/")
    local dtype = segs[7] -- yes. always!
    if not dtype then return end
    -- NB: _RIGHT_ HERE we make power bars look like anyone else. no special casing elsewhere!
    if dtype == "wh_in" then dtype = "cumulative_wh" end
    if not pl.tablex.find(cfg.store_types, dtype) then return end
    local device = segs[6]
    local channel = segs[8] -- may be nil
    local key = make_key(device, dtype, channel)
    ugly.info("Plausibly interesting interval data for key: %s", key)
end

local function handle_metadata(topic, jpayload)
    ugly.info("Processing metadata for %s", topic)
end

mqtt.ON_MESSAGE = function(mid, topic, jpayload, qos, retain)
    if mosq.topic_matches_sub(cfg.topic_data_in, topic) then
        if retain then
            ugly.debug("Skipping retained messages on topic: %s, we might have already processed that", topic)
            return
        end
        return handle_interval_data(topic, jpayload)
    end
    if mosq.topic_matches_sub(cfg.topic_metadata_in, topic) then
        return handle_metadata(topic, jpayload)
    end
end

-- TODO - CAREFUL! you may want to have an onconnect handler that creates the db connection internally.
-- you may want to do this so you can have the threaded interface, but make sure that you do everything on the correct thread.?

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
        -- FIXME - need to reconnect here!  (truly, monit restarting us is fast enough for 15minute data, but still....)
        error(err)
    end
    mqtt_idle_timer:set(cfg.MOSQ_IDLE_LOOP_MS)
end, cfg.MOSQ_IDLE_LOOP_MS)

uloop.run()