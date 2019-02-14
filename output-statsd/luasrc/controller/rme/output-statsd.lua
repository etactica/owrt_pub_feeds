--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-statsd", package.seeall)

function index()
    entry({"admin", "services", "output-statsd"}, cbi("rme/output-statsd"), "Output-StatsD", 20)
    entry({"admin", "services", "output-statsd", "diag"}, call("action_diag"), nil)
end

function action_diag()
    local rval = {
        friendly_name = "StatsD live stream exporter",
        expect_bridge = false,
        expect_process = true,
    }
    return luci.http.write_json(rval)
end
