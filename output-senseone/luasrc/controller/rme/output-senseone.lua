--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-senseone", package.seeall)
local ru = require("remake.utils")
local uci = require("luci.model.uci")

function index()
	entry({"admin", "services", "output-senseone"}, view("rme/output-senseone"), "Output-SenseOne", 20)
	entry({"admin", "services", "output-senseone", "diag"}, call("action_diag"), nil)
end

function action_diag()
	local gateid = ru.lookup_source_token()
	local cursor = uci.cursor()
	local username = cursor:get_first("output-senseone", "general", "username")
	local rval = {
		friendly_name = "SenseOne IoT Platform",
		expect_bridge = true,
		expect_process = false,
		bridge_notification_topic = string.format("%s/bridge/%s/state", username, gateid),
	}
	return luci.http.write_json(rval)
end


