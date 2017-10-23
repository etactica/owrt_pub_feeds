--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> June 2017
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-activitystream", "Message Output Daemon - Activity Stream",
  [[This contains some basic configuration for configuring the MQTT bridge of
the live data stream to Activity Stream
  <b>FIXME - insert links and text</b>
 ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "routing_key", "Routing Key",
	[[Provided by Activity Stream, unique for your account]])

s:option(Value, "username", "The MQTT bridge username", 
	[[Provided by Activity Stream, unique for your account]])
s:option(Value, "password", "The MQTT bridge password", 
	[[Provided by Activity Stream, unique for your account]])
s:option(Value, "address", "The MQTT broker address",
	[[Provided by Activity Stream, normally standard]])

return m
