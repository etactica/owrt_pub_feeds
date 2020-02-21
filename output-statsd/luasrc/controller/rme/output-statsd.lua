--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-statsd", package.seeall)
local pl = require("pl.import_into")()

function index()
    entry({"admin", "services", "output-statsd"}, cbi("rme/output-statsd"), "Output-StatsD", 20)
    entry({"admin", "services", "output-statsd", "diag"}, call("action_diag"), nil)
end

function action_diag()
    local _, code = pl.utils.execute("pidof output-statsd.lua 2>&1 >/dev/null")
    local rval = {
        friendly_name = "StatsD live stream exporter",
        expect_bridge = false,
        expect_process = true,
        process = code == 0,
    }
    return luci.http.write_json(rval)
end
