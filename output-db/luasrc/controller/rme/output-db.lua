--[[
--Karl Palsson, <karlp@etactica.com> Nov 2019
--]]
module("luci.controller.rme.output-db", package.seeall)

function index()
    entry({"admin", "services", "output-db"}, view("rme/output-db"), _("Output-Database"), 20)
    entry({"admin", "services", "output-db", "diag"}, call("action_diag"), nil)
end

function action_diag()
    local rval = {
        friendly_name = "Basic database exporter",
        expect_bridge = false,
        expect_process = true,
    }
    return luci.http.write_json(rval)
end
