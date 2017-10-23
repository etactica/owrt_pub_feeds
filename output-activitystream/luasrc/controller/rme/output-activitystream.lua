--[[
--Karl Palsson, <karlp@etactica.com> Oct 2017
--]]
module("luci.controller.rme.output-activitystream", package.seeall)

function index()
    entry({"admin", "services", "output-activitystream"}, cbi("rme/output-activitystream"), "Output-ActivityStream")
end


