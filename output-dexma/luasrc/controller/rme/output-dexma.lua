--[[
--Karl Palsson, <karlp@etactica.com> June 2017
--]]
module("luci.controller.rme.output-dexma", package.seeall)

function index()
    entry({"admin", "services", "output-dexma"}, cbi("rme/output-dexma"), "Output-Dexma", 20)
end


