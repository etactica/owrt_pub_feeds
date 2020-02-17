--[[
--Karl Palsson, <karlp@etactica.com> June 2017
--]]
module("luci.controller.rme.output-dexma", package.seeall)
local pl = require("pl.import_into")()
local json = require("cjson.safe")

function index()
    entry({"admin", "services", "output-dexma"}, view("rme/output-dexma"), "Output-Dexma", 20)
    entry({"admin", "services", "output-dexma", "diag"}, call("action_diag"), nil)
    entry({"admin", "services", "output-dexma", "diags2"}, template("rme/output-dexma-diags2"), nil)
end

-- This is only the front page summary diags.
-- The account page will autofetch the state file and display "more"
function action_diag()
    local _, code = pl.utils.execute("pidof output-dexma 2>&1 >/dev/null")
    local process = code == 0
    -- This will fail if anyone changes it in the daemon.
    local summary
    local status, err = pl.file.read("/tmp/output-dexma.state")
    if status then
        local details, errj = json.decode(status)
        if not details then
            process_extra = string.format("Process status file was invalid json, this is unexpected?! %s", errj)
        else
            if #details.posts > 0 then
                if details.posts[1].ok then
                    summary = string.format("Last message post to Dexma was good, sent %d readings", details.posts[1].n)
                else
                    process_extra = string.format("Last message post to dexma failed: %s", details.posts[1].err)
                end
            else
                process_extra = string.format("No data has been posted yet, perhaps the service has just started?")
            end
        end
    else
        if process then
            process_extra = string.format("Process status file not found, the process may have just started? %s", err)
        else
            process_extra = "Could not find any process named 'output-dexma'"
        end
    end
    local rval = {
        friendly_name = "Dexma - Your energy manager",
        expect_bridge = false,
        expect_process = true,
        expect_extra = true,
        process = process,
        -- extra will be shown if the process is not running
        process_extra = process_extra,
        custom_diags = "/diags2", -- This is a url relative to the service's main config page.
        custom_good = summary,
    }
    return luci.http.write_json(rval)
end