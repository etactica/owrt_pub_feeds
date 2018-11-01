--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-fake1", package.seeall)

function index()
    entry({"admin", "services", "output-fake1"}, cbi("rme/output-fake1"), "Output-FakeOne", 20)
end


