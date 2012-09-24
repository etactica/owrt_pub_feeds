--[[
LuCI model for mosquitto MQTT broker configuration management
Copyright OpenWrt.org, 2012

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

]]--

local datatypes = require("luci.cbi.datatypes")

m = Map("mosquitto", "Mosquitto MQTT Broker",
    [[mosquitto - the <a href='http://www.mosquitto.org'>blood thirsty</a> 
MQTT messaging broker.  Note, only some of the available configuration files
 are supported at this stage, use the checkbox below to use config generated
 by this page, or the stock mosquitto configuration file in 
 /etc/mosquitto/mosquitto.conf]])
 
s = m:section(TypedSection, "owrt", "OpenWRT")
s.anonymous = true
p = s:option(Flag, "use_uci", "Use this LuCI configuration page",
	[[If checked, mosquitto runs with a config generated
	from this page. (Or from UCI directly)  If unchecked, mosquitto
        runs with the config in /etc/mosquitto/mosquitto.conf
        (and this page is ignored)]])

s = m:section(TypedSection, "mosquitto", "Mosquitto")
s.anonymous = true

p = s:option(MultiValue, "log_dest", "Log destination",
    "You can have multiple, but 'none' will override all others")
p:value("stderr", "stderr")
p:value("stdout", "stdout")
p:value("syslog", "syslog")
p:value("topic", "$SYS/broker/log/[severity]")
p:value("none", "none")

s:option(Flag, "no_remote_access", "Disallow remote access to this broker",
	[[Outbound bridges will still work, but this will restrict clients
	from connecting via anything but localhost]])

-- we want to allow multiple bridge sections
s = m:section(TypedSection, "bridge", "Bridges",
    "You can configure multiple bridge connections here")
s.anonymous = true
s.addremove = true

conn = s:option(Value, "connection", "Connection name",
    "unique name for this bridge configuration")

local function validate_address(self, value)
    if (datatypes.host(value)) then
        return value
    end
    return nil, "Please enter a hostname or an IP address"
end

addr = s:option(Value, "address", "address", "address of remote broker")
addr.datatype = "string"
addr.validate = validate_address

-- TODO - make the in/out/both a dropdown/radio or something....
topics = s:option(DynamicList, "topic", "topic",
    "full topic string for mosquitto.conf, eg: 'power/# out 2'")

-- clientid = s:option(Value, "clientid", "Client Id", "Client id for bridge")
-- clientid.optional = true

s:option(Flag, "cleansession", "Clean session")

psk_identity = s:option(Value, "identity", "Bridge Identity", "Identity for TLS-PSK")
psk_identity.datatype = "string"

-- no hex validation available in datatypes
local function validate_psk_key(self, value)
    if (value:match("^[a-fA-F0-9]+$")) then
        return value
    end
    return nil, "Only hex numbers are allowed (use A-F characters and 0-9 digits)"
end

psk_key = s:option(Value, "psk", "Bridge PSK", "Key for TLS-PSK")
psk_key.password = true
psk_key.datatype = "string"
psk_key.validate = validate_psk_key

return m
