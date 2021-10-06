--[[
--Karl Palsson, <karlp@etactica.com> Nov 2019
--]]
module("luci.controller.rme.output-db", package.seeall)
local pl = require("pl.import_into")()

function index()
    entry({"admin", "services", "output-db"}, view("rme/output-db"), _("Output-Database"), 20)
    entry({"admin", "services", "output-db", "diag"}, call("action_diag"), nil).leaf = true
end

function action_diag()
	local pathinfo = luci.http.getenv("PATH_INFO") -- from luci
	local chunks = pl.stringx.split(luci.http.urldecode(pathinfo), "/")
	--"/admin/services/output-db/diag/instancename"
	if #chunks ~= 6 then
		luci.http.status(400, "Illegal Argument")
		return luci.http.write_json({
			err = "Diags without an instance id are unsupported",
			description = "You must provide an instance id as the last url fragment",
		})
	end
	local instance = chunks[6]

	-- Jump through some hoops to prevent executing user code, even though
	-- to reach this endpoint, they must be logged in with root credentials.
	-- The instance name itself is still user controlled, but it's checked
	-- by luci itself elsewhere.
	local cursor = uci.cursor()
	local allowed_instances = {}
	cursor:foreach("output-db", "instance", function(s)
		table.insert(allowed_instances, s[".name"])
	end)

	local allowed = pl.tablex.find(allowed_instances, instance)
	if not allowed then
		luci.http.status(400, "Illegal Argument")
		return luci.http.write_json({
			err = "Diags requested for an unknown instanceid",
			description = "You must provide a known and valid instance id as the last url fragment",
		})
	end

	local _, code = pl.utils.execute(string.format("pgrep -f 'output-db.lua -i %s' >/dev/null 2>&1", instance))
	local process = code == 0
    local rval = {
        friendly_name = "Basic database exporter",
        expect_bridge = false,
        expect_process = true,
        process = process,
    }
    return luci.http.write_json(rval)
end
