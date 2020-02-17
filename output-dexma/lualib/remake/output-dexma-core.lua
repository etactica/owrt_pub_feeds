--[[
The core of the output-dexma app.  Allows testing individual methods, but is not really a full "class"
as some lua modules can be.
Karl Palsson <karlp@etactica.com> Feb 2020 (this incarnation)
--]]

local json = require("cjson.safe")
local mosq = require("mosquitto")
local uci = require("uci")
local ugly = require("remake.uglylog")

local https = require("ssl.https")
local ltn12 = require("ltn12")

local Puni = require("posix.unistd")
local Pt = require("posix.time")
local pl = require("pl.import_into")()

local function timestamp_ms()
	local tspec = Pt.clock_gettime(Pt.CLOCK_REALTIME)
	return tspec.tv_sec * 1000 + math.floor(tspec.tv_nsec / 1e6)
end

-- "globals" that a few people need direct access to (we're not making an object just to hold them)
local statsd
local mqtt
local cfg = {}

local default_cfg = {
	APP_NAME = "output-dexma",
	MOSQ_CLIENT_ID = string.format("output-dexma-%d", Puni.getpid()),
	DEFAULT_LIMIT_QD = 300, --  ~100 15minute chunks per day, size depends on number of points, but non zero.
	DEFAULT_STORE_TYPES = {"cumulative_wh"},
	DEFAULT_TOPIC_DATA = "status/local/json/interval/%dmin/#",
	DEFAULT_TOPIC_METADATA = "status/local/json/cabinet/#",
	DEFAULT_TOPIC_STATE = "status/local/json/output-dexma/state",
	DEFAULT_STATSD_HOST = "localhost",
	DEFAULT_STATSD_PORT = 8125,
	DEFAULT_STATSD_NAMESPACE = "apps.output-dexma",
	DEFAULT_INTERVAL = 15, -- in minutes
	DEFAULT_FLUSH_INTERVAL_MS = 5000,
	--TEMPLATE_POST_URL = [[https://is3.dexcell.com/readings?source_key=%s]],
	--TEMPLATE_POST_URL=[[https://hookb.in/YVyJYVpm3MsgrkMNRBy8?source_key=%s]],
	--https://hookb.in/aBOpW7r9j9sp3Gwr9kOR
	TEMPLATE_POST_URL = [[https://localhost:8912/dexma]],
	--- How long to ignore data for while we process cabinet model information
	INITIAL_SLEEP_TIME = 5,
	-- Don't change this unless you change the diags too!
	DEFAULT_STATE_FILE = "/tmp/output-dexma.state",
}

local CODES = {
	MQTT_CONNECT_FAIL = 10,
	MQTT_SUBSCRIBE_FAIL = 11,
	MQTT_LOOP_FAIL = 12,
	MISSING_TLS = 20,
	MISSING_KEY = 21,
	STORE_QFULL = 30,
}

--- A map of data types that we can send to dexma, and how to get them.
-- Entries:
-- * un "user (visible) name" we present in the UI for them to select
-- * dt "datatype" the key in the interval stream that holds the data
-- * f "field" the field in the interval stream message to use
-- * n multiplier to apply to the interval stream data
-- * di "dexma id" the parameter id to use to send to dexma
local DEXMA_KEYS = {
	{un="cumulative_wh", dt="cumulative_wh", n=1e-3, f="max", di=402},
	{un="cumulative_varh", dt="cumulative_varh", n=1e-3, f="max", di=404},
	{un="voltage", dt="volt", f="mean", di=405},
	{un="current_max", dt="current", f="max", di=425},
	{un="current_mean", dt="current", f="mean", di=426},
	{un="pulse_count", dt="pulse_count", f="max", di=502},
	{un="temp", dt="temp", f="mean", di=701},
	{un="pf", dt="pf", f="mean", di=412},
}

local state = {
	sqn = 1,
	last_ts_flush_qd = timestamp_ms(),
	qd = {},
	-- This will be written to file/mqtt for external usage.
	ok = {
		posts = {},
		dids = {},
	}
}

---
local cabinet_model = {}

local function cfg_validate(c)
	-- Load UCI config too
	local x = uci.cursor()
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

	x:foreach(cfg.APP_NAME, "customvar", function(s)
		-- Unfortunately we don't get booleans here nicely from uci.
		if s.enabled == "1" or s.enabled == "true" then
			local n = tonumber(s.multiplier) or 1
			local dexma_type = {
				dt = s.datakey,
				n = n,
				f = s.field,
				di = s.parameterid,
			}
			table.insert(DEXMA_KEYS, dexma_type)
			ugly.info("Enabling custom variable: %s", pl.pretty.write(dexma_type))
		else
			ugly.debug("Skipping custom var that is disabled: %s", pl.pretty.write(s))
		end
	end)

	if #c.args.cafile == 0 then c.args.cafile = nil end
	if #c.args.capath == 0 then c.args.cafile = nil end
	if not c.args.cafile and not c.args.capath then
		pl.utils.quit(CODES.MISSING_TLS, "Either cafile or capath must be provided")
	end

	if c.args.key_is_file then
		ugly.debug("looking at file... %s", c.args.key)
		if pl.path.isfile(c.args.key) then
			c.args.key = pl.stringx.strip(pl.file.read(c.args.key))
		else
			pl.utils.quit(CODES.MISSING_KEY, "key file specified does not exist: %s", c.args.key)
		end
	else
		ugly.debug("looking at envvar... %s", c.args.key)
		c.args.key = os.getenv(c.args.key)
	end

	if not c.args.key then
		pl.utils.quit(CODES.MISSING_KEY, "key must be provided by either environment or file")
	end

	c.interval = c.uci.interval or c.DEFAULT_INTERVAL
	c.topic_data_in = string.format(c.DEFAULT_TOPIC_DATA, c.interval)
	c.topic_metadata_in = c.DEFAULT_TOPIC_METADATA
	c.topic_state_out = c.uci.topic_state_out or c.DEFAULT_TOPIC_STATE
	c.statsd_host = c.uci.statsd_host or c.DEFAULT_STATSD_HOST
	c.statsd_port = c.uci.statsd_port or c.DEFAULT_STATSD_PORT
	c.statsd_namespace = c.uci.statsd_namespace or c.DEFAULT_STATSD_NAMESPACE

	c.flush_interval_ms = tonumber(c.uci.flush_interval_ms) or c.DEFAULT_FLUSH_INTERVAL_MS
	c.limit_qd = tonumber(c.uci.limit_qd) or c.DEFAULT_LIMIT_QD
	c.store_types = c.uci.store_types or c.DEFAULT_STORE_TYPES
	c.state_file = c.uci.state_file or c.DEFAULT_STATE_FILE

	return c
end

local function mqtt_ON_DISCONNECT(was_clean, rc, str)
	if not was_clean then
		ugly.notice("Lost connection to MQTT broker! %d %s", rc, str)
	end
end

local function mqtt_ON_CONNECT(success, rc, str)
	if not success then
		ugly.crit("Failed to connect to MQTT broker: %s, %d: %s", cfg.args.mqtt_host, rc, str)
		os.exit(1)
	end
	for _,topic in ipairs({cfg.topic_data_in, cfg.topic_metadata_in}) do
		local mid, code, err = mqtt:subscribe(topic, 0)
		if not mid then
			ugly.err("Aborting, unable to subscribe to: %s: %d %s", topic, code, err)
			os.exit(CODES.MQTT_SUBSCRIBE_FAIL)
		end
	end
	ugly.debug("Connected and subscribed to MQTT broker: %s", cfg.args.mqtt_host)
end

--- Create/update our cache of the cabinet model.
--- we use this data to group breakers/channels and provide "meaningful" names up to dexma
local function handle_message_cabinet(mid, topic, jpayload, qos, retain)
	ugly.debug("processing cabinet data from topic: %s", topic)
	local payload, err = json.decode(jpayload)
	if not payload then
		ugly.warning("Invalid json in message on topic: %s, %s", topic, err)
		ugly.debug("Raw message=<%s>", jpayload)
		return
	end

	local cabinet = payload.cabinet
	if not cabinet then
		ugly.warning("No cabinet in cabinet model, ignoring on topic: %s", topic)
		return
	end
	local devid = pl.stringx.split(topic, "/")[5]
	if not devid then
		ugly.warning("No deviceid in topic?! can't assign to cabinet model")
		return
	end

	-- if there is an existing cabinet model for this device, just _replace_ it wholesale.
	cabinet_model[devid] = {}
	-- just keep the original branches, with a cabinet pointer on each one
	for _, b in pairs(payload.branches) do
		b.cabinet = cabinet
		table.insert(cabinet_model[devid], b)
	end
end

-- Look up/create a dexma "did" (deviceid) in the cabinet model
-- If the cabinet model is not available, we simply use the device ids.
local function get_did_from_model(model, devid, dtype, channel)
	for mdevid, mdev in pairs(model) do
		if mdevid == devid then
			--ugly.debug("Found a matching device, looking at mdev within: %s", pl.pretty.write(mdev))
			if not channel and #mdev == 1 then
				return string.format("%s-%s", mdev[1].cabinet, mdev[1].label)
			end
			if not channel then return nil, "Channel not specified and device has multiple data points in model?!" end
			for _, mbranch in pairs(mdev) do
				for nn,point in pairs(mbranch.points) do
					-- the channels are 1 based, but the cabinet model is historically 0 based.
					if point.reading + 1 == tonumber(channel) then
						return string.format("%s-%s-%d", mbranch.cabinet, mbranch.label, point.phase)
					end
				end
			end
		end
	end
	return nil, "Fell off the bottom of the model without matching"
end

local function get_did_default(devid, dtype, channel)
	if channel then
		return string.format("%s-%s-%s", devid, dtype, channel)
	else
		return string.format("%s-%s", devid, dtype)
	end
end

local function handle_message_data(mid, topic, jpayload, qos, retain)
	if retain then
		ugly.debug("Ignoring retained message on: %s, presumed already posted", topic)
		return
	end

	local segs = pl.stringx.split(topic, "/")
	local device = segs[6]
	local dtype = segs[7] -- yes. always!
	local channel = segs[8] -- may be nil
	if not dtype then return end
	-- NB: _RIGHT_ HERE we make power bars look like anyone else. no special casing elsewhere!
	if dtype == "wh_in" then dtype = "cumulative_wh" end

	-- First, get any dexma key objects matching the dtype.  _then_ if the key is in cfg.store_types, continue
	local found, dko = pl.tablex.find_if(DEXMA_KEYS, function(t, dt)
		if t.dt == dt then return t end
	end, dtype)
	if not found then
		ugly.debug("Ignoring datatype we have no dexma config for: %s", dtype)
		return
	end
	-- explicit custom vars simply don't provide a un field.
	if dko.un and not pl.tablex.find(cfg.store_types, dko.un) then
		ugly.debug("Ignoring uninteresting data of type: %s", dtype)
		return
	end
	if not dko.n then dko.n = 1 end
	if not dko.di then error("Programming error, dexma key contains no dexma parameter! " .. pl.pretty.write(dko)) end
	local did, _nodid = get_did_from_model(cabinet_model, device, dtype, channel)
	if did then
		state.ok.dids[did] = {has_model = true}
	else
		did = get_did_default(device, dtype, channel)
		state.ok.dids[did] = {has_model = false}
	end

	local payload, err = json.decode(jpayload)
	if not payload then
		statsd:increment("msgs.invalid-data")
		ugly.err("Non JSON payload on topic: %s: %s ", topic, err)
		return
	end
	statsd:increment("msgs.data")

	-- Note: we'll make multiple records here with the same "did", but that's ok, dexma shows it nicely grouped.

	-- dexma wants usage from 08:00 to 08:15 to report at 08:00
	local ts = Pt.strftime('%Y-%m-%dT%H:%M:00Z', Pt.gmtime(payload.ts_start / 1000))
	-- Create a new chunk for each interval's data
	if not state.qd[ts] then
		state.qd[ts] = {
			-- this will be shared by all entries at this timestamp, ie, we'll increment sqn for each window
			sqn = state.sqn + 1,
			values = {},
			ts = ts, -- Eases sorting and queue depth management later,
			retries = 0,
		}
		state.sqn = state.sqn + 1
	end

	local dex_value_reading = {
		did = did,
		sqn = state.qd[ts].sqn,
		ts = ts,
		values = {
			{ p = dko.di, v = payload[dko.f] * dko.n }
		},
	}

	-- queue everything so we can process all items the same way
	table.insert(state.qd[ts].values, dex_value_reading)
end

local function mqtt_ON_MESSAGE(mid, topic, jpayload, qos, retain)
	if mosq.topic_matches_sub(cfg.topic_data_in, topic) then
		local ok, err = pcall(handle_message_data, mid, topic, jpayload, qos, retain)
		if not ok then
			ugly.crit("Exception in message handler! %s", tostring(err))
		end
	end
	if mosq.topic_matches_sub(cfg.topic_metadata_in, topic) then
		local ok, err = pcall(handle_message_cabinet, mid, topic, jpayload, qos, retain)
		if not ok then ugly.crit("Exception in cabinet handler: %s", tostring(err)) end
	end
end

--- General HTTPS client object
-- @tparam url string endpoint
-- @tparam data anything, string or table. see options
-- @tparam userheaders table of header=value pair
-- @tparam opts table of user options.
--   options are
--     * json_encode => adds a content type header and json.encodes "data" before send
--        (default true)
--     * method => http method, defaults to POST
--     * verify => array of https req verify options,
--     * options => array of https req options options, (yes, that's the name)
--     * cafile => path to cafile, either this or capath must be provided
--     * capath => path to capath. either this or cafile must be provided, defaults to /etc/ssl/certs
-- @returns
-- On success (successfully communicated with the remote side!)
--      true, http_response_code, {table of headers} response_body
-- on fail
--      nil, text_reason
local function httppost(url, data, userheaders, opts)
	local respbody = {}
	local headers = userheaders or {}
	local useropts = opts or {}
	opts = pl.tablex.merge({
			json_encode = true,
			method = "POST",
			-- got these from prosody, look reasonable
			verify = { "peer", "client_once" },
			options = { "no_sslv2", "no_sslv3", "no_ticket", "no_compression", "cipher_server_preference", "single_dh_use", "single_ecdh_use" },
			capath = "/etc/ssl/certs",
		}, useropts, true)

	local reqbody = data
	if opts.json_encode then
		reqbody = json.encode(data)
		headers["Content-Type"] = "application/json;charset=utf-8"
	end
	ugly.debug("posting now: %s", reqbody)
	headers["content-length"] = #reqbody
	local http_req = {
		method = opts.method,
		url = url,
		source = ltn12.source.string(reqbody),
		headers = headers,
		sink = ltn12.sink.table(respbody),
		verify = opts.verify,
		options = opts.options,
	}
	if opts.cafile then
		http_req.cafile = opts.cafile
	else
		http_req.capath = opts.capath
	end
	local r, c, h = https.request(http_req)
	-- r = 1 if it got _any_ response from the server.  r = nil means client side error.
	if r then
		return true, c, h, table.concat(respbody)
	else
		return nil, c
	end
end


local function flush_qd()
	-- how are we batching messages from different topics that are the same 15 minute interval?
	-- we can just batch based on timestamps, no problem.
	local remaining = {}

	for ts, data in pairs(state.qd) do
		ugly.debug("attempting to psot data for ts %s", ts)
		local url = string.format(cfg.TEMPLATE_POST_URL, cfg.args.id)
		local headers = {
			["x-dexcell-source-token"] = cfg.args.key,
		}
		local httpok, c, h, body = httppost(url, data.values, headers)
		if httpok then
			statsd:increment(string.format("http-post.code-%d", c))
			if c == 200 then
				statsd:increment("post-success")
				ugly.info("Posted %d readings for ts: %s", #data.values, ts)
				table.insert(state.ok.posts, 1,{at=timestamp_ms(ts), ts=ts, ok=true, n=#data.values})
			else
				statsd:increment("post-failure")
				data.retries = data.retries + 1
				ugly.warning("Dexma POST returned failure (%d): queueing for retry #%d: %s", c, data.retries, body)
				table.insert(remaining, data)
				table.insert(state.ok.posts, 1,{at=timestamp_ms(ts), ts=ts, ok=false, err=c, retry=data.retries})
			end
		else
			-- This would normally indicate a _client_ side error!
			statsd:increment("post-error")
			data.retries = data.retries + 1
			ugly.err("Failed to make http post at all?! %s: queuing for retry #%d", c, data.retries)
			table.insert(remaining, data)
			table.insert(state.ok.posts, 1,{at=timestamp_ms(ts), ts=ts, ok=false, err=c, retry=data.retries})
		end
		-- TODO - potentially, add a backoff here for a bit of jitter in http posting?
		-- This will attempt each queued reading immediately back to back right now.
	end
	-- sort remaining by ts, so that people could choose most recent, or oldest to discard, and so that
	-- regardless of what we choose, we're consistent each time. (fixed sort right now still)
	table.sort(remaining, function(a,b) return a.ts < b.ts end)
	-- Now we throw away entries longer than our queue depth...
	if #remaining > cfg.limit_qd then
		local discarded = #remaining - cfg.limit_qd
		ugly.warning("Discarding %d queued readings as queue limit (%d) exceeded", discarded, cfg.limit_qd)
		statsd:increment("queue-discards", discarded)
		remaining = pl.tablex.removevalues(remaining, cfg.limit_qd)
	end
	-- And re-insert them in indexable form.
	local new_qd = {}
	for _,v in ipairs(remaining) do
		new_qd[v.ts] = v
	end
	state.qd = new_qd

	-- Truncate our status file to last ~x attempts too
	state.ok.posts = pl.tablex.removevalues(state.ok.posts, 8)
	state.ok.qd = #remaining
	local status_message = json.encode(state.ok)
	if status_message ~= state.last_status_message then
		pl.file.write(cfg.state_file, status_message)
		mqtt:publish(cfg.topic_state_out, status_message, 0, true)
		state.last_status_message = status_message
	end
end

local function do_main(args)
	mosq.init()
	cfg = default_cfg
	cfg.args = args
	ugly.initialize(cfg.APP_NAME, args.verbose or 4)

	cfg = cfg_validate(cfg)
	ugly.debug("Starting operation with config: %s", pl.pretty.write(cfg))
	-- Delete any existing state file.
	pl.file.delete(cfg.state_file)

	statsd = require("statsd")({
		namespace = cfg.statsd_namespace,
		host = cfg.statsd_host,
		port = cfg.statsd_port,
	})

	mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)
	-- Clear our state message on exit
	mqtt:will_set(cfg.topic_state_out, nil, 0, true)

	if not mqtt:connect(args.mqtt_host, 1883, 60) then
		ugly.err("Aborting, unable to make MQTT connection")
		os.exit(CODES.MQTT_CONNECT_FAIL)
	end

	mqtt.ON_DISCONNECT = mqtt_ON_DISCONNECT
	mqtt.ON_MESSAGE = mqtt_ON_MESSAGE
	mqtt.ON_CONNECT = mqtt_ON_CONNECT

	while true do
		local rc, code, mqerr = mqtt:loop()
		if not rc then
			-- let process monitoring handle this. losing our messages coming in is ~fatal.
			ugly.warning("mqtt loop failed, exiting: %d %s", code, mqerr)
			os.exit(CODES.MQTT_LOOP_FAIL)
		end

		local now = timestamp_ms()
		if now - state.last_ts_flush_qd > cfg.flush_interval_ms then
			flush_qd(cfg)
			local delta = timestamp_ms() - now
			statsd:timer("flush-qd", delta)
			state.last_ts_flush_qd = now
		end
	end

end

local M = {
	do_main = do_main,
	httppost = httppost,
}

return M