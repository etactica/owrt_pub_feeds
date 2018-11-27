--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-senseone", package.seeall)

function index()
	entry({"admin", "services", "output-senseone"}, cbi("rme/output-senseone"), "Output-SenseOne", 20)
	entry({"admin", "services", "output-senseone", "diag"}, call("action_diag"), nil)
end

function action_diag()
	local rval = {
		friendly_name = "SenseOne IoT Platform",
		expect_bridge = true,
		expect_process = false,
	}
	return luci.http.write_json(rval)
end


