--[[
--Karl Palsson, <karlp@etactica.com> June 2017
--]]
module("luci.controller.rme.output-dexma", package.seeall)
local pl = require("pl.import_into")()
local json = require("cjson.safe")

function index()
    entry({"admin", "services", "output-dexma"}, view("rme/output-dexma"), "Output-Dexma", 20)
end


