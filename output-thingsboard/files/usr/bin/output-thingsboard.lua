#!/usr/bin/lua
--[[
    Karl Palsson, 2018 <karlp@etactica.com>
    This is an "output" daemon for ThingsBoard.
]]

local json = require("cjson.safe")
local mosq = require("mosquitto")
local ugly = require("remake.uglylog")

local Puni = require("posix.unistd")
local pl = require("pl.import_into")()


local args = pl.lapp [[
  output-thingsboard

  Output's all live readings directly to thingsboard as keyed telemetry.
  Listens for shared attribute updates and logs them
  Listens for server->client RPC calls and logs and replies with dummy data.

  Options:
    -H,--host (default "localhost") MQTT host to use
    -v,--verbose (0..7 default 5) Logging level, higher == more
]]

local cfg = {
	APP_NAME = "output-thingsboard",
	MOSQ_CLIENT_ID = string.format("output-thingsboard-%d", Puni.getpid()),
	TOPIC_LISTEN_DATA = "status/local/json/device/#",
	TOPIC_LISTEN_IN_ATTRIBUTES = "ext/thingsboard/in/attributes/#",
	TOPIC_LISTEN_IN_RPC = "ext/thingsboard/in/rpc/#",
	TOPIC_PUBLISH_RPC = "ext/thingsboard/out/rpc/%d",
	TOPIC_PUBLISH_TELEMETRY = "ext/thingsboard/telemetry",
}


ugly.initialize(cfg.APP_NAME, args.verbose or 4)

mosq.init()
local mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

mqtt.ON_CONNECT = function(success, rc, str)
	if not success then
		ugly.crit("Failed to connect to MQTT broker: %s, %d: %s", args.host, rc, str)
		os.exit(1)
	end
	if not mqtt:subscribe(cfg.TOPIC_LISTEN_DATA, 0) then
		ugly.crit("Aborting, MQTT Subscribe failed: to %s:%s.", args.host, cfg.TOPIC_LISTEN_DATA)
		os.exit(1)
	end
	if not mqtt:subscribe(cfg.TOPIC_LISTEN_IN_ATTRIBUTES, 0) then
		ugly.crit("Aborting, MQTT Subscribe failed: to %s:%s.", args.host, cfg.TOPIC_LISTEN_IN_ATTRIBUTES)
		os.exit(1)
	end
	if not mqtt:subscribe(cfg.TOPIC_LISTEN_IN_RPC, 0) then
		ugly.crit("Aborting, MQTT Subscribe failed: to %s:%s.", args.host, cfg.TOPIC_LISTEN_IN_RPC)
		os.exit(1)
	end
	ugly.notice("Successfully connected and listening for data")
end


--- Common code for validating senml entry list
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

--- Common code for validating senml metadata
-- will modify meta if necessary!
local function validate_meta(eee)
	if eee.bn and type(eee.bn) ~= "string" then return false end
	-- safe to modify, not required, but need string concat to work
	if not eee.bn then eee.bn = "" end

	if eee.bt and type(eee.bt) ~= "number" then return false end
	return true
end

--- Process newly arrived data messages.
-- Needs to validate the data message, then actually handle it.
local function handle_message_data(mid, topic, jpayload, qos, retain)
	local chunks = pl.stringx.split(topic, "/")
	if #chunks < 5 then
		ugly.debug("Ignoring invalid/unprobed device on topic: %s", topic)
		return
	end
	local payload, err = json.decode(jpayload)
	if not payload then
		ugly.warning("Invalid json in message on topic: %s, %s", topic, err)
		ugly.debug("Raw message=<%s>", jpayload)
		return
	end
	if not payload.hwc then
		ugly.info("Ignoring unsuitable json format on topic: %s", topic);
		return
	end
	if payload.hwc.error then
		ugly.debug("Ignoring failed reading")
		return
	end
	if type(payload.senml) ~= "table" then
		ugly.warning("device data without a senml table?!")
		return
	end
	if type(payload.senml.e) ~= "table" then
		ugly.warning("device data with an empty senml.e field?!")
		return
	end
	if not validate_meta(payload.senml) then
		ugly.warning("senml metadata (bt,bn etc) was invalid?!")
		return
	end
	if not validate_entries(payload.senml.e, payload.senml.bt) then
		ugly.warning("senml entry set contained invalid entries, ignoring batch!")
		return
	end
	if not payload.senml.bt then payload.senml.bt = 0 end

	local telemetry = {ts = payload.senml.bt, values = {}}

	for _, e in ipairs(payload.senml.e) do
		local key = payload.senml.bn .. e.n
		telemetry.values[key] = e.v
	end

	mqtt:publish(cfg.TOPIC_PUBLISH_TELEMETRY, json.encode(telemetry), 1, false)

end

local function handle_attributes(topic, jpayload)
	ugly.alert("Received attribute update from server: %s", jpayload)
end

local function handle_rpc(topic, jpayload)
	local txid = topic:sub(#"ext/thingsboard/in/rpc/" + 1)
	local payload, err = json.decode(jpayload)
	if not payload then
		ugly.warning("Invalid json in message on topic: %s, %s", topic, err)
		ugly.debug("Raw message=<%s>", jpayload)
		return
	end
	if not payload.method then
		ugly.info("RPC method missing: %s", topic);
		return
	end
	local params = payload.params or {}

	--------------------------------------
	-- TODO insert your custom RPC handling here....
	ugly.alert("Received RPC request (txid: %d): method: %s: params: %s", txid, payload.method, json.encode(params))

	local response = {
		result = "ok", somethingelse = 43,
		inputparams = params
	}
	-- XXX we presume that we can reply always, even if the request was "oneway"
	mqtt:publish(cfg.TOPIC_PUBLISH_RPC:format(txid), json.encode(response), 1, false)

	-- END OF USER CODE SECTION -----------

end

mqtt.ON_MESSAGE = function(mid, topic, jpayload, qos, retain)
	if mosq.topic_matches_sub(cfg.TOPIC_LISTEN_DATA, topic) then
		local ok, err = pcall(handle_message_data, mid, topic, jpayload, qos, retain)
		if not ok then ugly.crit("Exception in live data handler: %s", tostring(err)) end
	end
	if mosq.topic_matches_sub(cfg.TOPIC_LISTEN_IN_ATTRIBUTES, topic) then
		local ok, err = pcall(handle_attributes, topic, jpayload)
		if not ok then ugly.crit("Exception in attribute handler: %s", tostring(err)) end
	end
	if mosq.topic_matches_sub(cfg.TOPIC_LISTEN_IN_RPC, topic) then
		local ok, err = pcall(handle_rpc, topic, jpayload)
		if not ok then ugly.crit("Exception in RPC handler: %s", tostring(err)) end
	end
end

mqtt:connect(args.host, 1883, 60)

while true do
	local rc, code, err = mqtt:loop()
	if not rc then
		-- let process monitoring handle this.
		ugly.warning("mqtt loop failed, exiting: %d %s", code, err)
		os.exit(1)
	end
end
