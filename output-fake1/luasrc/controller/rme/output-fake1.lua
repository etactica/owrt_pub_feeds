--[[
--Karl Palsson, <karlp@etactica.com> Sept 2018
--]]
module("luci.controller.rme.output-fake1", package.seeall)

local U = require("posix.unistd")

function index()
    entry({"admin", "services", "output-fake1"}, cbi("rme/output-fake1"), "Output-FakeOne", 20)
    entry({"admin", "services", "output-fake1", "diag"}, call("action_diag"), nil)
end

function action_diag()
    local ok, extra, code = U.access("/tmp/my-special-file")
    local rval = {
        friendly_name = "Fake Sample Output",
        expect_bridge = true,
        -- Provide this if you use a non mqtt bridge connection id
        --mqtt_connection_match = "blah",

        expect_process = true,
        -- coerce to true boolean.  0 is "true" in lua, but not javascript.
        process = not not ok, -- boolean to indicate process is running
        -- extra will be shown if the process is not running
        process_extra = extra -- raw text <pre> to show if not running
    }
    return luci.http.write_json(rval)
end


