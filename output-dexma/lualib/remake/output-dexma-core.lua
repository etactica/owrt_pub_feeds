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
	DEFAULT_LIMIT_QD = 500, --  ~100 15minute chunks per day, size depends on number of points, but non zero.
	DEFAULT_STORE_TYPES = {"cumulative_wh"},
	DEFAULT_TOPIC_DATA = "status/local/json/interval/%dmin/#",
	DEFAULT_TOPIC_METADATA = "status/local/json/cabinet/#",
	DEFAULT_TOPIC_STATE = "status/local/json/output-dexma/state",
	DEFAULT_STATSD_HOST = "localhost",
	DEFAULT_STATSD_PORT = 8125,
	DEFAULT_STATSD_NAMESPACE = "apps.output-dexma",
	DEFAULT_INTERVAL = 15, -- in minutes
	DEFAULT_FLUSH_INTERVAL_MS = 500,
	DEFAULT_DEXMA_POST_URL = [[https://is3.dexcell.com/readings?source_key=%s]],
	--TEMPLATE_POST_URL=[[https://hookb.in/YVyJYVpm3MsgrkMNRBy8?source_key=%s]],
	--https://hookb.in/aBOpW7r9j9sp3Gwr9kOR
	-- How long to wait to ensure that all MQ messages for an interval have been received
	DEFAULT_MQ_QUIET_TIME_MS = 5000,
	-- Don't change this unless you change the diags too!
	DEFAULT_STATE_FILE = "/tmp/output-dexma.state",
	-- These types should be named with "label-<channel>" others as just "label"
	DEFAULT_PER_CHANNEL_TYPES = {
		"current",
		"volt",
		"pf",
		"power",
	}
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
-- * n (optional) multiplier to apply to the interval stream data
-- * di "dexma id" the parameter id to use to send to dexma
local DEXMA_KEYS = {
	{un="cumulative_wh", dt="cumulative_wh", n=1e-3, f="max", di=402},
	{un="cumulative_varh", dt="cumulative_varh", n=1e-3, f="max", di=404},
	{un="voltage", dt="volt", f="mean", di=405},
	{un="current_max", dt="current", f="max", di=425},
	{un="current_mean", dt="current", f="mean", di=426},
	{un="pulse_count", dt="pulse_count", f="max", di=502},
	{un="power_mean", dt="power", f="mean", di=401},
	{un="power_max", dt="power", f="max", di=418},
	{un="temp", dt="temp", f="mean", di=701},
	{un="pf", dt="pf", f="mean", di=412},
}

local state = {
	sqn = 1,
	flush_last_ts = timestamp_ms(),
	qd = {},
	-- This will be written to file/mqtt for external usage.
	ok = {
		posts = {},
		dids = {},
	}
}

---
local cabinet_model = {}

-- For a nominal number, add jitter
local function jitter(nominal, factor)
	local f = 10;
	if factor then f = factor end
	local offset = nominal / f;
	return nominal - offset + math.random() * (offset * 2);
end


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

	if c.args.cafile and #c.args.cafile == 0 then c.args.cafile = nil end
	if c.args.capath and #c.args.capath == 0 then c.args.capath = nil end
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

	c.url_template = c.uci.url_template or c.DEFAULT_DEXMA_POST_URL
	c.interval = c.uci.interval or c.DEFAULT_INTERVAL
	c.mq_quiet_time_ms = c.uci.mq_quiet_time_ms or c.DEFAULT_MQ_QUIET_TIME_MS
	c.topic_data_in = string.format(c.DEFAULT_TOPIC_DATA, c.interval)
	c.topic_metadata_in = c.DEFAULT_TOPIC_METADATA
	c.topic_state_out = c.uci.topic_state_out or c.DEFAULT_TOPIC_STATE
	c.statsd_host = c.uci.statsd_host or c.DEFAULT_STATSD_HOST
	c.statsd_port = c.uci.statsd_port or c.DEFAULT_STATSD_PORT
	c.statsd_namespace = c.uci.statsd_namespace or c.DEFAULT_STATSD_NAMESPACE

	c.flush_interval_ms = tonumber(c.uci.flush_interval_ms) or c.DEFAULT_FLUSH_INTERVAL_MS
	state.flush_jitter_time = jitter(c.flush_interval_ms)
	c.limit_qd = tonumber(c.uci.limit_qd) or c.DEFAULT_LIMIT_QD
	c.store_types = c.uci.store_types or c.DEFAULT_STORE_TYPES
	c.state_file = c.uci.state_file or c.DEFAULT_STATE_FILE
	-- TODO no support for loading a list from config at this point, see if we actually need to do this? Will custom types need this?
	c.per_channel_types = c.DEFAULT_PER_CHANNEL_TYPES

	-- Load custom variables
	x:foreach(cfg.APP_NAME, "customvar", function(s)
		-- Unfortunately we don't get booleans here nicely from uci.
		if s.enabled == "1" or s.enabled == "true" then
			local n = tonumber(s.multiplier) or 1
			local dexma_type = {
				dt = s.datakey,
				n = n,
				f = s.field,
				di = tonumber(s.parameterid),
				un = "custom-" .. s[".name"], -- use the automatic uci config id as a un key.
			}
			if dexma_type.di and dexma_type.f and dexma_type.dt then
				table.insert(DEXMA_KEYS, dexma_type)
				table.insert(cfg.store_types, dexma_type.un)
				ugly.info("Enabling custom variable: %s/%s", dexma_type.dt, dexma_type.f)
			else
				ugly.warning("Skipping invalid custom variable: %s", pl.pretty.write(dexma_type))
			end
		else
			ugly.debug("Skipping custom var that is disabled: %s", pl.pretty.write(s))
		end
	end)

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
						-- If it's the type of data that _must_ be done per channel, make a channel based key.
						-- energy for instance can be summed, but not volts, or pf
						if pl.tablex.find(cfg.per_channel_types, dtype) then
							return string.format("%s-%s-%d", mbranch.cabinet, mbranch.label, point.phase)
						else
							return string.format("%s-%s", mbranch.cabinet, mbranch.label)
						end
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

--- Find the dexma type mapping(s) for a given mqtt message data type
-- We might find multiple types, if we want to make multiple dexma types from the
-- same base type, eg, both current max and current mean are both from teh same "current"
-- mqtt message!
-- @param dt the type name from the mqtt topic, eg "current"
-- @param dexma_keys the set of dexma variables we know how to send
-- @param store_types the list of config strings enabled to send, eg "current_max, voltage_mean"
-- @return[1] a list of suitable dexma key objects.
-- @return[2] nil, reason for not found
local function find_datatypes(dt, dexma_keys, store_types)
	-- First, get a list of the right data types
	local dkos = pl.tablex.filter(dexma_keys, function(t, key)
		if t.dt == key then return true end
	end, dt)
	if not dkos then
		return nil, "No matching dexma config for type: " .. dt
	end

	-- then, keep all that are on the allowed list
	local matches = pl.tablex.filter(dkos, function(dko, allowed)
		for _,v in pairs(allowed) do
			if v == dko.un then return true end
		end
		return false
	end, store_types)
	if #matches > 0 then
		return matches
	else
		return nil, "data type is not configured to send: " .. dt
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

	local dkos, reason = find_datatypes(dtype, DEXMA_KEYS, cfg.store_types)
	if not dkos then
		ugly.debug("Ignoring reading: %s", reason)
		return
	end
	local hwid = get_did_default(device, dtype, channel)
	local did, _nodid = get_did_from_model(cabinet_model, device, dtype, channel)
	if did then
		state.ok.dids[did] = {has_model = true}
	else
		did = hwid
		state.ok.dids[did] = {has_model = false}
	end

	local payload, err = json.decode(jpayload)
	if not payload then
		statsd:increment("msgs.invalid-data")
		ugly.err("Non JSON payload on topic: %s: %s ", topic, err)
		return
	end
	statsd:increment("msgs.data")
	-- reset the flush time to now, this stops us from flushing until after we've been idle after a message chunk.
	state.flush_last_ts = timestamp_ms()

	-- Note: we'll make multiple records here with the same "did", but that's ok, dexma shows it nicely grouped.

	-- dexma docs imply start, but empiracally, it needs to be the end.
	local ts = Pt.strftime('%Y-%m-%dT%H:%M:00Z', Pt.gmtime(payload.ts_end / 1000))
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

	local function handle_dko(dko)
		if not dko.n then dko.n = 1 end
		if not dko.di then error("Programming error, dexma key contains no dexma parameter! " .. pl.pretty.write(dko)) end
		local dex_value_reading = {
			did = did,
			sqn = state.qd[ts].sqn,
			ts = ts,
			value = {
				p = dko.di,
				v = payload[dko.f] * dko.n,
				hwid = hwid,  -- we keep this for later, to make sure we're not merging duplicates, only multi channels
			},
		}

		-- queue everything so we can process all items the same way
		-- this will _happily_ enter repeated timestamps over again, we should _replace_ with a new reading for the samw hwid
		local handled = false
		for _,item in pairs(state.qd[ts].values) do
			if item.did == dex_value_reading.did and
				item.value.hwid == dex_value_reading.value.hwid and
				item.value.p == dex_value_reading.value.p then
				item.value.v = dex_value_reading.value.v
				ugly.debug("Replacing repeated data at ts for %s (%s)", item.did, item.value.hwid)
				handled = true
			end
		end
		if not handled then
			table.insert(state.qd[ts].values, dex_value_reading)
		end
	end

	-- Remember that we could be processing multiple types from the same message
	for _,dko in pairs(dkos) do
		handle_dko(dko)
	end
end

local function mqtt_ON_MESSAGE(mid, topic, jpayload, qos, retain)
	if mosq.topic_matches_sub(cfg.topic_data_in, topic) then
		local ok, err = pcall(handle_message_data, mid, topic, jpayload, qos, retain)
		if not ok then
			ugly.crit("Exception in message handler! %s", tostring(err))
		end
		state.last_mq_message_ts = timestamp_ms()
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
	https.TIMEOUT = 10 -- Default is 60, which is _way_ too long for our little single threaded brain.
	local blen = #reqbody
	ugly.debug("posting %d bytes to url: %s, body: %s", blen, url, reqbody)
	headers["content-length"] = blen
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

--- Coalesce multiple readings from the same points into single values.
-- This results in compact json with only one entry for each label, with multiple parameters, instead
-- of separate entries for every parameter.  Dexma was ok with that, but coalescing is required to be able
-- to sum up readings, such as per channel energy from bars.
local function coalesce(blob)
	local out = {
		sqn = blob.sqn,
		ts = blob.ts,
		retries = blob.retries,
		values = {},
	}
	for _,v in pairs(blob.values) do
		-- v is a {ts, value{ v,p,hwid}, sqn, did} object
		local did = v.did
		-- must find in the long list, based on inner did...
		local found, match = pl.tablex.find_if(out.values, function(element, arg)
			if element.did == arg then return element end
		end, did)
		if found then
			local handled = false
			-- look for any matching in the output set to sum/join with
			for _, prior in pairs(match.values) do
				--ugly.debug("Considering prior.p: %d vs v.value.p %d for prior.hwid: %s, v.value.hwid: %s", prior.p, v.value.p, prior.hwid, v.value.hwid)
				if prior.p == v.value.p then
					if prior.hwid ~= v.value.hwid then
						prior.v = prior.v + v.value.v
						ugly.debug("Summing for: %s (%f) from different hwid: (%s|%s)", did, prior.v, prior.hwid, v.value.hwid)
						-- this _still_ lets a hwid/ts pair contribute multiple times if it was in the source more than once.
						-- but thankfully, we swallow them on insertion instead.
					end
					handled = true
				end
			end
			if not handled then
				table.insert(match.values, v.value)
			end
		else
			-- This lets us build the multi-value output set without making the internal code more complicated.
			if v.value then
				table.insert(out.values, {ts= v.ts, values={v.value}, sqn=v.sqn, did=v.did})
			elseif v.values then
				-- pre-coalseced! just put back into the output data!
				table.insert(out.values, v)
			end
		end
	end
	return out
end


--- Attempt to flush our stored readings.
-- We only attempt to post one message each call here, to allow the main loop to still run healthily and service
-- MQ messages.  Even if we only post one message every ~500ms, with a weekend's worth of offline data, that's only
-- ~192 messages, or ~90seconds to repost them all.  That avoids us locking up attempting to retry readings,
-- and also avoids hammering the dexma backend too much on retries.  (If _they_ have problems, we're going to be
-- trying every ~500ms though, so we _may_ wish to implement some extended backoff based on certain response codes.
-- Algorithm is:
-- * sort the stored readings by ts to find oldest (or, via config, newest for instance)
-- * pop the first one
-- * post it,
-- * if it fails, push it back on front.
-- * return and let jitter and looping retry.
-- @returns nil - if nothing to post, or nothing to retry
-- @returns <integer> the retry count of the last attempt if a retry was required.
local function flush_qd()
	local size = pl.tablex.size(state.qd)
	ugly.debug("entering flush.... with %d queued", size)
	if size == 0 then return end

	-- We get NNN messages every interval, make sure we've got them all before we try and process.
	local now = timestamp_ms()
	if now - state.last_mq_message_ts < cfg.mq_quiet_time_ms then return end

	local function sort_oldest_first(a,b)
		return a.ts < b.ts
	end

	-- remember, state.qd is just the same data, with element.ts being used as the key, you can just toss the keys and still have all data.
	local remaining = pl.tablex.values(state.qd)
	table.sort(remaining, sort_oldest_first)

	local proposed = table.remove(remaining, 1)

	local postable = coalesce(proposed)

	local function post_to_dexma(data)
		local ts = data.ts
		local url = string.format(cfg.url_template, cfg.args.id)
		local headers = {
			["x-dexcell-source-token"] = cfg.args.key,
		}
		-- Now, we stored a "hwid" tag in the data, to avoid duplicates and track the original source.
		-- but we can't send that to dexma, so strip it out here.
		for _,v in pairs(data.values) do
			for _,vv in pairs(v.values) do
				vv.hwid = nil
			end
		end
		local httpok, c, h, body
		if cfg.args.nopost then
			httpok, c, h, body = true, 200, nil, "fake post was ok :)"
			ugly.info("NotPosting to dexma: %s", pl.pretty.write(data.values))
		else
			if (cfg.uci.no_verify) then
				httpok, c, h, body = httppost(url, data.values, headers, {verify={}})
			else
				httpok, c, h, body = httppost(url, data.values, headers)
			end
		end
		if httpok then
			statsd:increment(string.format("http-post.code-%d", c))
			if c == 200 then
				statsd:increment("post-success")
				ugly.notice("Posted %d readings for ts: %s", #data.values, ts)
				table.insert(state.ok.posts, 1,{at=timestamp_ms(ts), ts=ts, ok=true, n=#data.values})
				return true
			else
				statsd:increment("post-failure")
				data.retries = data.retries + 1
				ugly.warning("Dexma POST returned failure (%d): queueing for retry #%d: %s", c, data.retries, body)
				table.insert(state.ok.posts, 1,{at=timestamp_ms(ts), ts=ts, ok=false, err=c, retry=data.retries})
				return nil, data
			end
		else
			-- This would normally indicate a _client_ side error!
			statsd:increment("post-error")
			data.retries = data.retries + 1
			ugly.err("Failed to make http post at all?! %s: queuing for retry #%d", c, data.retries)
			table.insert(state.ok.posts, 1,{at=timestamp_ms(ts), ts=ts, ok=false, err=c, retry=data.retries})
			return nil, data
		end
	end

	local postok, data_to_retry = post_to_dexma(postable)
	if not postok then
		table.insert(remaining, 1, postable)
	end

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

	if data_to_retry then
		return data_to_retry.retries
	end
end

local function do_init(args)
	math.randomseed(os.time())
	mosq.init()
	args = args or {}
	cfg = default_cfg
	cfg.args = args
	ugly.initialize(cfg.APP_NAME, args.verbose or 4)

	cfg = cfg_validate(cfg)

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
			namespace = cfg.statsd_namespace,
			host = cfg.statsd_host,
			port = cfg.statsd_port,
		})
	end
end

local function do_main()
	ugly.debug("Starting operation with config: %s", pl.pretty.write(cfg))
	-- Delete any existing state file.
	pl.file.delete(cfg.state_file)

	mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)
	-- Clear our state message on exit
	mqtt:will_set(cfg.topic_state_out, nil, 0, true)

	if not mqtt:connect(cfg.args.mqtt_host, 1883, 60) then
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
		if now - state.flush_last_ts > state.flush_jitter_time then
			local retries = flush_qd(cfg)
			local delta = timestamp_ms() - now
			statsd:timer("flush-qd", delta)
			state.flush_last_ts = now
			-- Backoff a bit more if it's retrying a lot.  This will automatically speed up again on successes.
			-- TODO - allow this to be configurable?
			local extra_backoff = 0
			if retries and retries > 10 then extra_backoff = 10*1000 end
			state.flush_jitter_time = jitter(cfg.flush_interval_ms) + extra_backoff

			local status_message = json.encode(state.ok)
			if status_message ~= state.last_status_message then
				pl.file.write(cfg.state_file, status_message)
				mqtt:publish(cfg.topic_state_out, status_message, 0, true)
				state.last_status_message = status_message
			end

		end
	end

end

local M = {
	init = do_init,
	main = do_main,
	httppost = httppost,
	jitter = jitter,
	on_message = mqtt_ON_MESSAGE,
	coalesce = coalesce,
	_state = state,
	_find_datatypes = find_datatypes,
}

return M