--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> June 2017
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-dexma", "Message Output Daemon - Dexma",
  [[This contains some basic configuration for a very simple output formatter
 that parses eTactica live stream data, and posts it to a given stream on
  <b>FIXME - insert dexma links and text</b>
 ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "source_key", "ID for your stream",
	[[Is the MAC address of the gateway or the unique key that identifies the datasource which the data belongs to]])
s:option(Value, "dexcell_source_token", "The authentication token for every gateway",
	[[Aka, password. this is required to be able to publish to the stream]])

return m
