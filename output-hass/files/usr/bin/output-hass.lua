#!/usr/bin/lua
--[[
    Karl Palsson, 2021 karlp@tweak.net.au
]]

local pl = require("pl.import_into")()
local args = pl.lapp [[
    -v,--verbose (0..7 default 4) Logging level, higher == more
    -i,--instance (optional string) Instance id, used to generate namespaces
    -I,--ignore_model Ignore the cabinet model.
        By default, we attempt to create metadata based on the cabinet model
        This does mean that if you edit your model, your metrics will change,
        but that was probably what you wanted anyway!
        With this flag, the cabinet model will be ignored, and metrics will be
        published using only the hardware identifiers (deviceid.metric.channel)

    MQTT Options.  (For both listening and publishing)
    -H,--mqtt_host (default "localhost")
    -p,--mqtt_port (default 1883)
    -u,--mqtt_username (optional string) username, if required
    -P,--mqtt_password (optional string) password, if required
    --mqtt_psk (optional string) pre-shared key in hexadecimal, no leading 0x, for TLS-PSK
    --mqtt_psk_id (optional string) client identity string for TLS-PSK
    --mqtt_cafile (optional string) file containing CA certs
    --mqtt_capath (optional string) directory containing CA certs
    --mqtt_certfile (optional string) file containing client certificate
    --mqtt_keyfile (optional string) keyfile for client certificate

    StatsD Options
    -S,--statsd_host (default "localhost") StatsD server address
    --statsd_port (default 8125) StatsD port
    --statsd_namespace (default "apps.output-hass.{instance}") Namespace for this data
]]

local app = require("remake.output-hass-app")

if args.statsd_namespace == "apps.output-hass.{instance}" then
    if args.instance then
        args.statsd_namespace = string.format("apps.output-hass.%s", args.instance)
    else
        args.statsd_namespace = "apps.output-hass.default"
    end
end
local statsd = require("statsd")({
    namespace = args.statsd_namespace,
    host = args.statsd_host,
    port = args.statsd_port,
})

local us = app.init(args, statsd)
us:run()