--[[
--Karl Palsson, <karlp@etactica.com> Nov 2019
--]]
module("luci.controller.rme.output-sustainable-exergy", package.seeall)

function index()
    entry({"admin", "services", "output-sustainable-exergy"}, view("rme/output-sustainable-exergy"), _("Output-Sustainable Exergy"), 20)
    entry({"admin", "services", "output-sustainable-exergy", "diag"}, call("action_diag"), nil)
end

function action_diag()
    local rval = {
        friendly_name = "Sustainable Exergy database exporter",
        expect_bridge = false,
        expect_process = true,
    }
    return luci.http.write_json(rval)
end
