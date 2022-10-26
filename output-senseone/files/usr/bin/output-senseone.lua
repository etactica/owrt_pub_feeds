#!/usr/bin/lua
--[[
Karl Palsson 2022 <karlp@etactica.com>

Listens to x minute interval data, and republishes with optional metric
renaming, to an "outbound" tree.  Externally, the mqtt broker is configured
to bridge the now complete outbound tree directly.
]]

local uci = require("uci")
local mosq = require("mosquitto")
local PU = require("posix.unistd")
local ugly = require("remake.uglylog")

local pl = require("pl.import_into")()
local args = pl.lapp [[
    -H,--host (default "localhost") MQTT host to listen to
    -v,--verbose (0..7 default 4) Logging level, higher == more
    -i,--interval (1min|5min|15min|60min default 15min) Reporting interval to republish
]]

local cfg = {
    APP_NAME = "output-senseone",
    MOSQ_CLIENT_ID = string.format("output-senseone-%d", PU.getpid()),
    TOPIC_LISTEN_DATA = string.format("status/local/json/interval/%s/+/+/#", args.interval),
    TOPIC_LISTEN_ALERTS = "status/local/json/alert/+/#",
    TOPIC_LISTEN_CABINET = "status/local/json/cabinet/#",
    TOPIC_PUBLISH_BASE = "ext/output-senseone/out/status",
	DEFAULT_STATSD_HOST = "localhost",
	DEFAULT_STATSD_PORT = 8125,
	DEFAULT_STATSD_NAMESPACE = "apps.output-senseone",
	opts = args,
}

ugly.initialize(cfg.APP_NAME, cfg.opts.verbose or 4)

local function cfg_validate(c)
    -- Load UCI config too
    local x = uci.cursor(uci.get_confdir())
    x:foreach(c.APP_NAME, "general", function(s)
        if c.uci then
            error("Duplicate 'general' section in uci config!")
        end
        c.uci = s
    end)
    if not c.uci then
        ugly.warning("No configuration file found?! creating an empty stub")
        c.uci = {}
    end

	c.statsd_host = c.uci.statsd_host or c.DEFAULT_STATSD_HOST
	c.statsd_port = c.uci.statsd_port or c.DEFAULT_STATSD_PORT
	c.statsd_namespace = c.uci.statsd_namespace or c.DEFAULT_STATSD_NAMESPACE

	-- Process the stored type lists into something that's easier to work with
	c.stored = {}
	for _, k in pairs(c.uci.store_types) do
		if k == "+" then
			c.store_all = true -- special treatment.
		end
		local raw = pl.stringx.split(k, "=")
		local metric_in = raw[1]
		local metric_out = metric_in
		if raw[2] then
			metric_out = raw[2]
		end
		c.stored[metric_in] = metric_out

		-- Special handling for power bars, include "wh_in" if cumulative_wh is enabled.
		if metric_in == "cumulative_wh" then
			c.stored.wh_in = "wh_in"
		end
	end
end

-- load uci into config
cfg_validate(cfg)
local statsd = require("statsd")({
	namespace = cfg.statsd_namespace,
	host = cfg.statsd_host,
	port = cfg.statsd_port,
})

mosq.init()
local mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

local function handle_data(topic, jpayload)
    statsd:meter("msgs.input-data", 1)
    local extra = pl.stringx.replace(topic, "status/local/json", "")
    -- we're left with "interval/xxmin/<deviceid>/<metric>/<channel-extra>"
    -- we need to look in our configuration and decide if we care about this data or not...
    --ugly.debug("extra is %s", extra)
    local pieces = pl.stringx.split(extra, "/")
    local metric_in = pieces[5]

	if cfg.store_all then
        -- publish everything as is, we're set to "everything"
        mqtt:publish(cfg.TOPIC_PUBLISH_BASE .. extra, jpayload, 1, false)
        statsd:increment("msgs.output-data")
        return
    end
    -- otherwise, see if the input metric is listed..
	local metric_out = cfg.stored[metric_in]
	if metric_out then
		pieces[5] = metric_out
		extra = pl.stringx.join("/", pieces)
		local outt = cfg.TOPIC_PUBLISH_BASE .. extra
		mqtt:publish(outt, jpayload, 1, false)
		statsd:increment("msgs.output-data")
		return
    end
    statsd:increment("msgs.ignored")
end

mqtt.ON_MESSAGE = function(mid, topic, jpayload, qos, retain)
    if mosq.topic_matches_sub(cfg.TOPIC_LISTEN_DATA, topic) then
        return handle_data(topic, jpayload)
    end
    -- otherwise, it's cabinet models or alerts, so just do the base replacement
    local extra = pl.stringx.replace(topic, "status/local/json", "")
    mqtt:publish(cfg.TOPIC_PUBLISH_BASE .. extra, jpayload, 1, false)
    statsd:increment("msgs.alerts-sent")
end

mqtt.ON_CONNECT = function(ok, code, errs)
	local mid
	ugly.debug("connect returned: %s %d %s", tostring(ok), code, errs)
	if not ok then
		ugly.err("Aborting, connected, but refused access: %d:%s", code, errs)
		os.exit(1)
	end
	mid, code, errs = mqtt:subscribe(cfg.TOPIC_LISTEN_DATA, 0)
	if not mid then
		ugly.err("Aborting, unable to subscribe to data stream: %d:%s", code, errs)
		os.exit(1)
	end
	mid, code, errs = mqtt:subscribe(cfg.TOPIC_LISTEN_CABINET, 0)
	if not mid then
		ugly.err("Aborting, unable to subscribe to cabinet data stream: %d:%s", code, errs)
		os.exit(1)
	end
	mid, code, errs = mqtt:subscribe(cfg.TOPIC_LISTEN_ALERTS, 0)
	if not mid then
		ugly.err("Aborting, unable to subscribe to alerts: %d:%s", code, errs)
		os.exit(1)
	end
	ugly.notice("MQTT (RE)Connected happily to %s", cfg.opts.host)
	statsd:increment("mqtt.connected")
end

if not mqtt:connect(cfg.opts.host, 1883, 60) then
	ugly.err("Aborting, unable to make MQTT connection")
	os.exit(1)
end

mqtt:loop_forever()
