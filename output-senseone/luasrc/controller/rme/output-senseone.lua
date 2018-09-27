--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-senseone", package.seeall)

function index()
    entry({"admin", "services", "output-senseone"}, cbi("rme/output-senseone"), "Output-SenseOne", 20)
end


