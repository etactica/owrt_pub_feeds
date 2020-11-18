#!/usr/bin/lua
--[[
    Karl Palsson, November 2020 <karlp@etactica.com>
]]

local pl = require("pl.import_into")()
local core = require("remake.io-charging-on-core")

local args = pl.lapp [[
    Listen (mqtt) to mains meters and charger consumption reports,
    dynamically compute available power, and write (modbus) to
    all connected chargers.  Orku Natturunnar implementation

    -H,--mqtt_host (default "localhost") MQTT host to listen to
    -v,--verbose (0..7 default 5) Logging level, higher == more
    -S,--statsd_host (default "localhost") StatsD server address
    --statsd_port (default 8125) StatsD port
    --statsd_namespace (default "io-charging-on") Namespace for this data
]]

local ugly = require("remake.uglylog")
ugly.initialize("io-charging-on", args.verbose or 4)

core.init(args)
local ok, err = xpcall(core.main, debug.traceback)
if not ok then
    ugly.emerg("Crashed! %s", err)
    os.exit(1)
end
