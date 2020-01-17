#!/usr/bin/lua
--[[
    Karl Palsson, 2019 <karlp@remake.is>
]]

local json = require("cjson.safe")
-- cjson specific
json.encode_sparse_array(true)
local mosq = require("mosquitto")
mosq.init()
local PU = require("posix.unistd")
local Pt = require("posix.time")
local uci = require("uci")
local ugly = require("remake.uglylog")

local pl = require("pl.import_into")()
local cliargs = pl.lapp [[
    -H,--mqtt_host (default "localhost") MQTT host to listen to
    -v,--verbose (0..7 default 4) Logging level, higher == more
    -i,--instance (string) UCI service instance to run

    "All" configuration is loaded from the UCI file for the given instance
]]

-- "globals" that a few people need direct access to (we're not making an object just to hold them)
local statsd
local mqtt
local cfg = {}
local conn

-- Default global configuration
local default_cfg = {
    APP_NAME = "output-db",
    MOSQ_CLIENT_ID = string.format("output-db-%s-%d", cliargs.instance, PU.getpid()),
    MOSQ_IDLE_LOOP_MS = 500,
    DEFAULT_STORE_TYPES = {"cumulative_wh"},
    -- We're going to listen to more than we theoretically need to, but we can just drop it
    DEFAULT_TOPIC_DATA = "status/+/json/interval/%dmin/#",
    DEFAULT_TOPIC_METADATA = "status/+/json/cabinet/#",
    DEFAULT_STATSD_HOST = "localhost",
    DEFAULT_STATSD_PORT = 8125,
    DEFAULT_STATSD_NAMESPACE = "apps.output-db",
    DEFAULT_INTERVAL = 15, -- in minutes
    DEFAULT_LIMIT_QD = 2000, -- 32 devices * 1 energy value => 15 hours of 15minute data, for instance.
    DEFAULT_INTERVAL_FLUSH_QD = 5000, -- in milliseconds
    PATH_DEFAULT = "/usr/share/output-db",
    PATH_USER = "/etc/output-db",
}

local CODES = {
    MQTT_CONNECT_FAIL = 10,
    MQTT_SUBSCRIBE_FAIL = 11,
    MQTT_LOOP_FAIL = 12,
    DB_CONNECT_FAIL = 20,
    DB_CREATE_FAIL = 21,
    DB_QFULL = 22,
    READ_QUERY = 30,
}

-- checks and fills in defaults
-- raises if required fields are not available
-- @tparam[table] c Input config object, defaults plus any initial user arguments
local function cfg_validate(c)
    c.interval = c.uci.interval or c.DEFAULT_INTERVAL
    c.topic_data_in = string.format(c.DEFAULT_TOPIC_DATA, c.interval)
    c.topic_metadata_in = c.DEFAULT_TOPIC_METADATA
    c.statsd_host = c.uci.statsd_host or c.DEFAULT_STATSD_HOST
    c.statsd_port = c.uci.statsd_port or c.DEFAULT_STATSD_PORT
    c.statsd_namespace = c.uci.statsd_namespace or string.format("%s.%s", c.DEFAULT_STATSD_NAMESPACE, c.args.instance)
    c.limit_qd = tonumber(c.uci.limit_qd) or c.DEFAULT_LIMIT_QD
    c.interval_flush_qd = tonumber(c.uci.interval_flush_qd) or c.DEFAULT_INTERVAL_FLUSH_QD
    if c.uci.store_types and pl.tablex.find(c.uci.store_types, "_all") then
        c.store_types = nil
    else
        c.store_types = c.uci.store_types or c.DEFAULT_STORE_TYPES
    end

    local function read_template(instance, type)
        local err, custom, default
        custom, err = pl.file.read(string.format("%s/custom.%s.%s.query", c.PATH_USER, instance, type))
        default, err = pl.file.read(string.format("%s/default.%s.query", c.PATH_DEFAULT, type))
        if not custom and not default then
            ugly.fatal("No custom query and unable to read default either: %s", err)
            os.exit(CODES.READ_QUERY)
        end
        return custom or default
    end

    c.template_data = read_template(c.args.instance, "data")
    c.template_metadata_update = read_template(c.args.instance, "metadata-update")
    c.template_metadata_insert = read_template(c.args.instance, "metadata-insert")
    return c
end

local function timestamp_ms()
    local tspec = Pt.clock_gettime(Pt.CLOCK_REALTIME)
    return tspec.tv_sec * 1000 + math.floor(tspec.tv_nsec / 1e6)
end

-- Live variables, just kept in a table for sanity of access
local state = {
    qd = {},
    last_ts_flush_qd = timestamp_ms(),
}

--- Connect and return a connection object
-- or nil, reason
local function db_connect(cfg)
    local dname = string.format("luasql.%s", cfg.uci.driver)
    local driver = require (dname)
    if not driver then
        return nil, "Couldn't load driver for: " .. dname
    end
    local env = driver[cfg.uci.driver]()
    if not env then
        return nil, "Couldn't open environment for driver"
    end
    local params = {cfg.uci.dbname, cfg.uci.dbuser, cfg.uci.dbpass, cfg.uci.dbhost}
    if cfg.uci.dbport then table.insert(params, cfg.uci.dbport) end
    return env:connect(table.unpack(params))
end

local function db_create(conn, cfg)
    -- Load the schema for this driver.
    local driver = cfg.uci.driver
    -- This is convoluted, because mysql doesn't let you run multiple statements in one go.
    local schemaf, ferr = pl.file.read(string.format("%s/schema.%s.sql", cfg.PATH_DEFAULT, driver))
    if not schemaf then
        return nil, string.format("Couldn't load schema for driver: %s: %s", driver, ferr)
    end

    -- split on sql statements, only include full statements. no trailers.
    local schemas = pl.stringx.split(schemaf, ';', pl.stringx.count(schemaf, ';'))
    for _,schema in ipairs(schemas) do
        ugly.debug("Attempting to process schema statement <%s>", schema)
        local rows, err = conn:execute(schema)
        if not rows then
            return nil, string.format("Failed to update schema: %s", err)
        else
            ugly.debug("schema fragment execution successful")
        end
    end
    return true
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

-- return a properly formatted "safe" sql to execute based on a metadata branch/point
-- We write a row of metadata for every single point.  This makes some duplicates,
-- but makes it much easier to match things up in a database later.
-- NOTE: switching to luadbi and parameterized queries will dramatically change how the templates would work!
local function make_query_metadata_update(cabinet, deviceid, branch, point)
    -- make a timestamp for "last change"
    local ts_str = os.date("%FT%T")
    -- create a context object for them to use
    local context = {
        deviceid = deviceid,
        cabinet = cabinet,
        breakersize = branch.ampsize,
        label = branch.label,
        point = point.reading + 1, -- the interval data uses logical channel numbers, not zero based.
        phase = point.phase,
        gateid = cfg.gateid,
        ts = ts_str,
    }

    local t = pl.text.Template(cfg.template_metadata_update)
    return t:substitute(context)
end

-- return a properly formatted "safe" sql to execute based on a metadata branch/point
-- This is just for doing an insert of the "primary key" (even though we don't tag it as such)
local function make_query_metadata_insert(deviceid, point)
    -- make a timestamp for "last change"
    local ts_str = os.date("%FT%T")
    -- create a context object for them to use
    local context = {
        deviceid = deviceid,
        point = point.reading + 1, -- the interval data uses logical channel numbers, not zero based.
        ts = ts_str,
    }
    local t = pl.text.Template(cfg.template_metadata_insert)
    return t:substitute(context)
end

-- return a properly formatted "safe" sql to execute based on the data payload
-- NOTE: switching to luadbi and parameterized queries will dramatically change how the templates would work!
local function make_query_data(entry)
    local key = entry.key
    local payload = entry.payload
    -- Convert our timestamp into an iso8601 datestring, so that it parses natively into different database backends
    -- (we don't care about milliseconds on minute level interval reporting)
    local ts_end = math.floor(payload.ts_end / 1000)
    local ts_str = os.date("%FT%T", ts_end)
    local value
    if key:find("cumulative_wh") then
        value = payload.max
    else
        value = payload.mean
    end
    -- Enrich the payload a bit before we give it to the template.
    payload.pname = key
    payload.selected = value
    payload.ts_ends = ts_str
    payload.period = cfg.interval * 60
    payload.gateid = cfg.gateid
    for k,v in pairs(entry.context) do
        payload[k] = v
    end

    local t = pl.text.Template(cfg.template_data)
    return t:substitute(payload)
end

local function handle_interval_data(topic, jpayload)
    local segs = pl.stringx.split(topic, "/")
    local dtype = segs[7] -- yes. always!
    if not dtype then return end
    -- NB: _RIGHT_ HERE we make power bars look like anyone else. no special casing elsewhere!
    if dtype == "wh_in" then dtype = "cumulative_wh" end
    if cfg.store_types and not pl.tablex.find(cfg.store_types, dtype) then
        ugly.debug("Ignoring uninteresting data of type: %s", dtype)
        return
    end
    local device = segs[6]
    local channel = segs[8] -- may be nil
    local key = make_key(device, dtype, channel)

    -- find or insert key into sources table. -- or just _not_....
    -- let them have what they like here?

    local payload, err = json.decode(jpayload)
    if payload then
        statsd:increment("msgs.data")
        local extra_context = {
            device = device,
            dtype = dtype,
            channel = channel,
        }
        -- All data readings are queued so they can be handled the same way
        table.insert(state.qd, {key=key, payload=payload, context=extra_context})
    else
        statsd:increment("msgs.invalid-data")
        ugly.err("Non JSON payload on topic: %s: %s ", topic, err)
    end
end

local function handle_metadata(topic, jpayload)
    local function handle_clean_json(p)
        if not p.type or p.type ~= "profile" then
            return nil, "unknown message type? " .. tostring(p.type)
        end
        if not p.version then
            return nil, "profile version not provided"
        end
        local n = 0

        -- For use with update/insert queries, that return a rowcount, not a cursor
        local function do_query(query, prefix)
            local ok, serr = conn:execute(query)
            if ok then
                if ok == 0 then
                    return nil, prefix
                else
                    return true
                end
            else
                ugly.crit("Unhandled error attempting query: %s", serr)
                error("Unhandled error attempting query" .. serr)
            end
        end

        if p.version == 0.3 then
            local cabinet = p.cabinet
            local deviceid = p.deviceid
            for _,branch in ipairs(p.branches) do
                for _,point in ipairs(branch.points) do
                    local ok, serr
                    local mkey = string.format("%s:%d", deviceid, point.reading + 1)
                    -- get the query for an update, and do that first.
                    local update = make_query_metadata_update(cabinet, deviceid, branch, point)
                    local insert = make_query_metadata_insert(deviceid, point)
                    ok, serr = do_query(update, "row not found for update")
                    if not ok then
                        ok, serr = do_query(insert, "row not found for insert")
                        if not ok then
                            ugly.err("Failed to insert metadata row: %s", serr)
                            statsd:increment("db.insert-fail-meta")
                            error("Metadata row couldn't be created for: " .. mkey)
                        end
                        ok, serr = do_query(update, "row not found for update")
                        if not ok then
                            -- FIXME - attempt to store a short queue here?  retry at all? or jsut log and continue?
                            ugly.err("Failed to store metadata: %s", serr)
                            statsd:increment("db.insert-fail-meta")
                            error("Metadata row wasn't found at update time for: " .. mkey)
                        end
                    end
                    statsd:increment("db.insert-good-meta")
                    n = n + 1
                end
            end
        else
            return nil, "unhandled profile version: " .. tostring(p.version)
        end
        return n
    end

    local payload, err = json.decode(jpayload)
    if payload then
        statsd:increment("msgs.metadata")
        local records, err = handle_clean_json(payload)
        if records then
            ugly.info("Processed %s into %d database records", topic, records)
        else
            ugly.warning("Problems with json message on %s: %s", topic, err)
            statsd:increment("msgs.invalid-metadata")
        end
    else
        statsd:increment("msgs.invalid-metadata")
        ugly.err("Non JSON payload on topic: %s: %s ", topic, err)
    end
end

local function mqtt_ON_MESSAGE(mid, topic, jpayload, qos, retain)
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

local function mqtt_ON_DISCONNECT(was_clean, rc, str)
    if not was_clean then
        ugly.notice("Lost connection to MQTT broker! %d %s", rc, str)
    end
end

local function mqtt_ON_CONNECT(success, rc, str)
    if not success then
        ugly.notice("Failed to connect to MQTT: %d %s", rc, str)
        return
    end
    for _,topic in ipairs({cfg.topic_data_in, cfg.topic_metadata_in}) do
        local mid, code, err = mqtt:subscribe(topic, 0)
        if not mid then
            ugly.err("Aborting, unable to subscribe to: %s: %d %s", topic, code, err)
            os.exit(CODES.MQTT_SUBSCRIBE_FAIL)
        end
    end
end

local function db_flush_qd(cfg)
    local ok, err
    local todo = {} -- will be the new list
    for _,entry in ipairs(state.qd) do
        err = "No valid database connection"
        if conn then
            ok, err = conn:execute(make_query_data(entry))
        end
        if ok then
            ugly.debug("Successfully exported data for key: %s", entry.key)
            statsd:increment("db.insert-good")
        else
            statsd:increment("db.insert-fail")
            table.insert(todo, entry)
        end
    end
    state.qd = todo

    -- Now, special handling if we couldn't drain our queue
    if #state.qd > 0 then
        if #state.qd > cfg.limit_qd then
            ugly.crit("Too many queued data messages, aborting")
            os.exit(CODES.DB_QFULL)
        end
        -- attempt to reconnect the database, next iteration will attempt to reflush
        if conn then
            local closed = conn:close()
            if not closed then ugly.debug("Connection close failed, probably already closed") end
        end
        conn, err = db_connect(cfg)
        if conn then
            ugly.notice("Database connection re-established!")
        else
            ugly.warning("Couldn't (re)connect to database (qdepth: %d): %s", #state.qd, err)
        end
    end
    statsd:gauge("qd-len", #state.qd)
end

local function do_main(args, default_cfg)
    local ok, err
    cfg = default_cfg
    cfg.args = args
    ugly.initialize(string.format("%s.%s", cfg.APP_NAME, args.instance), args.verbose or 4)

    -- Read instance configuration and merge
    local x = uci.cursor()
    x:foreach(cfg.APP_NAME, "instance", function(s)
        if s[".name"] ~= args.instance then return end
        cfg.uci = s
    end)

    x:foreach("system", "system", function(s)
        if s.rme_stablemac then
            cfg.gateid = s.rme_stablemac
            return
        end
    end)

    cfg = cfg_validate(cfg)
    ugly.debug("Starting operations with config: %s", pl.pretty.write(cfg))

    statsd = require("statsd")({
        namespace = cfg.statsd_namespace,
        host = cfg.statsd_host,
        port = cfg.statsd_port,
    })

    mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

    if not mqtt:connect(args.mqtt_host, 1883, 60) then
        ugly.err("Aborting, unable to make MQTT connection")
        os.exit(CODES.MQTT_CONNECT_FAIL)
    end

    mqtt.ON_DISCONNECT = mqtt_ON_DISCONNECT
    mqtt.ON_MESSAGE = mqtt_ON_MESSAGE
    mqtt.ON_CONNECT = mqtt_ON_CONNECT

    conn, err = db_connect(cfg)
    -- If we can't connect at startup, just let process monitoring retry later.
    if not conn then
        ugly.crit(string.format("Couldn't connect: %s", err))
        os.exit(CODES.DB_CONNECT_FAIL)
    end

    if cfg.uci.schema_create then
        ok, err = db_create(conn, cfg)
        if not ok then
            ugly.crit("Failed to create database on request: %s", err)
            os.exit(CODES.DB_CREATE_FAIL)
        end
        ugly.notice("Database schema creation complete")
    else
        ugly.notice("Assuming database is compatible with validation. If you get errors, check your queries or schemas!");
    end

    ugly.notice("Application startup complete")

    while true do
        local rc, code, mqerr = mqtt:loop()
        if not rc then
            -- let process monitoring handle this. losing our messages coming in is ~fatal.
            ugly.warning("mqtt loop failed, exiting: %d %s", code, mqerr)
            os.exit(CODES.MQTT_LOOP_FAIL)
        end

        -- Metadata isn't updated very often, and is sent on every start anyway, so we don't queue metadata
        local now = timestamp_ms()
        if now - state.last_ts_flush_qd > cfg.interval_flush_qd then
            db_flush_qd(cfg)
            state.last_ts_flush_qd = now
        end
    end
end

do_main(cliargs, default_cfg)
