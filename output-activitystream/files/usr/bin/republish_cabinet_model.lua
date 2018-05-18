#!/usr/bin/lua
-- A file for Activity Stream's republishing needs.
-- Ástvaldur Hjartarson, 2017 <ah@etactica.com>
--
local lapp = require("pl.lapp")
local PU = require("posix.unistd")
local ugly = require("remake.uglylog")
local mosq = require("mosquitto")
require "socket"


--  Global variables.   --
local name = "republish-cabinet"
local cfg = {
	WAIT_FOR_CABINET_MS = 2000,
	MOSQ_CLIENT_ID = string.format("%s-%d", name, PU.getpid()),
	TOPIC = "status/+/json/cabinet/#",
}
local cabinet = {}
local midarr = {}

local args = lapp [[
-H, --host (default 'localhost') Modbus TCP and MQTT host to connect to.
-v, --verbose (0..7 default 6) Logging level, higher == more
--]]
ugly.initialize(name, args.verbose)
local function timestamp_ms()
	return math.ceil(socket.gettime()*1000)
end

---- Initialize MQTT connections and start background message processing
mosq.init()
local mqtt = mosq.new(cfg.MOSQ_CLIENT_ID, true)

mqtt.ON_MESSAGE = function(mid, original_topic, jpayload, qos, retain)
	ugly.debug("Topic recieved was: %s", orginal_topic)
	local msg_table = {["topic"] = original_topic, ["msg"] = jpayload}
	table.insert(cabinet, msg_table)
end

mqtt.ON_PUBLISH = function(mid,topic)
	ugly.debug("Resend : %s", topic)
	table.remove(midarr)
end

if not mqtt:connect(args.host, 1883, 60) then
	ugly.err("Aborting, Unable to make MQTT connection.")
	os.exit(1)
end

if not mqtt:subscribe(cfg.TOPIC, 0) then
	ugly.err("Aborting, unable to subscribe to %s", cfg.TOPIC)
	os.exit(1)
end

-- Make sure we get all the messages, delay exit by 2 sec
local timestamp_begin   = timestamp_ms()
local timestamp_current = timestamp_ms()
while  (timestamp_current - timestamp_begin < cfg.WAIT_FOR_CABINET_MS) do
	local rc, err = mqtt:loop(100)
	if not rc then
		ugly.err("MQTT connection failed. Failed to recieve messages")
		os.exit(1)
	end
	timestamp_current = timestamp_ms()
end

if not mqtt:unsubscribe(cfg.TOPIC) then
	ugly.err("Aborting, unable to unsubscribe from %s", cfg.TOPIC)
	os.exit(1)
end

local amount_that_was_published = 0
for i,v in pairs(cabinet) do
	if v.topic then
		local mid, code, err = mqtt:publish(v.topic, v.msg, 1, true)
		amount_that_was_published = amount_that_was_published + 1
		if err then
			ugly.err("Unexpected error when republishing MQTT. %d %s", code, err)
			os.exit(1)
		else
			table.insert(midarr, mid)
		end
	end
end

local escape_timer = timestamp_ms()
while (#midarr > 0) do
	local rc, err = mqtt:loop(100)
	if not rc then
		ugly.err("MQTT connection failed, %s exiting.", name)
		os.exit(1)
	end
	if ((timestamp_ms() - escape_timer) > 10000) then
		ugly.err("Failed to republish cabinet messages. Took to longer than 10 sec")
		os.exit(1)
	end
end
ugly.info("%d device cabinet models were republished.", amount_that_was_published)
mqtt:disconnect()
