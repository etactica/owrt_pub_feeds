#!/usr/bin/lua
--[[
    Karl Palsson, 2019 <karlp@remake.is>
]]

local uloop = require("uloop")
uloop.init()
local ugly = require("remake.uglylog")

local pl = require("pl.import_into")()
local args = pl.lapp [[
    -H,--mqtt_host (default "localhost") MQTT host to listen to
    -v,--verbose (0..7 default 4) Logging level, higher == more
    -S,--statsd_host (default "localhost") StatsD server address
    --statsd_port (default 8125) StatsD port
    --statsd_namespace (default "live") Namespace for this data
    -I,--ignore_model Ignore the cabinet model.
        By default, we attempt to create metrics based on the cabinet model
        This does mean that if you edit your model, your metrics will change,
        but that was probably what you wanted anyway!
        With this flag, the cabinet model will be ignored, and metrics will be
        published using the fallback hardware identifiers (deviceid.metric.channel)
]]

local our_app = require("remake.output-statsd-app")

local statsd = require("statsd")({
    namespace = args.statsd_namespace,
    host = args.statsd_host,
    port = args.statsd_port,
})

local osapp = our_app.init(args, statsd)
osapp:connect()



local mqtt_read = uloop.fd_add(osapp.mqtt:socket(), function(ufd, events)
    osapp.mqtt:loop_read()
end, uloop.ULOOP_READ)

local mqtt_write = uloop.fd_add(osapp.mqtt:socket(), function(ufd, events)
    osapp.mqtt:loop_write()
end, uloop.ULOOP_WRITE)

local mqtt_idle_timer
mqtt_idle_timer = uloop.timer(function()
    -- just handle the mosquitto idle/misc loop
    local success, errno, err = osapp.mqtt:loop_misc()
    if not success then
        local err = string.format("Lost MQTT connection: %s", err)
        ugly.crit(err)
        error(err)
    end
    mqtt_idle_timer:set(osapp.opts.MOSQ_IDLE_LOOP_MS)
end, osapp.opts.MOSQ_IDLE_LOOP_MS)

uloop.run()
