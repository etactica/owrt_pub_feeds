--[[
--Karl Palsson, <karlp@remake.is> March, 2015
--]]
module("luci.controller.rme.output-sparkfun", package.seeall)

function index()
    entry({"admin", "services", "output-sparkfun"}, cbi("rme/output-sparkfun"), "Output-Sparkfun")
end


