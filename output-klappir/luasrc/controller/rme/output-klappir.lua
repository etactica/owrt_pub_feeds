--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-klappir", package.seeall)

local __ = luci.i18n.translate

function index()
    entry({"admin", "services", "output-klappir"}, cbi("rme/output-klappir"), _("Output-Klappir"), 20)
    entry({"admin", "services", "output-klappir", "diag"}, call("action_diag"), nil)
end

function action_diag()
    local rval = {
        friendly_name = __("Klappir Smart Environmental Management"),
        expect_bridge = true,
        expect_process = false,
    }
    return luci.http.write_json(rval)
end
