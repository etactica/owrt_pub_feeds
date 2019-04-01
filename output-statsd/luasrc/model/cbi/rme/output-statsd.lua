--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> Sept 2018
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-statsd", "Message Output Daemon - Statsd",
    [[This service handles bridging eTactica live stream data, and posting
     <em>all</em> live variables to a statsd server.
    <h4>More information</H4>
    ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "statsd_host", "The StatsD server hostname",
	[[Hostname of StatsD server to post to]])
s:option(Value, "statsd_port", "The StatsD listen port",
	[[Normally standard]])

return m
