--[[
--Karl Palsson, <karlp@etactica.com> Jul 2018
--]]
module("luci.controller.rme.output-thingsboard", package.seeall)

function index()
    entry({"admin", "services", "output-thingsboard"}, cbi("rme/output-thingsboard"), "Output-ThingsBoard", 20)
end


