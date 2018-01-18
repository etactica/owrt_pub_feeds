--[[
--Karl Palsson, <karlp@etactica.com> Jan 2018
--]]
module("luci.controller.rme.output-openenergi", package.seeall)

function index()
    entry({"admin", "services", "output-openenergi"}, cbi("rme/output-openenergi"), "Output-Open Energi", 20)
end


