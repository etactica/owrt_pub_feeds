--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> Sept 2018
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]
local _ = luci.i18n.translate

m = Map("output-statsd", "Message Output Daemon - Statsd",
	_([[This service handles bridging eTactica live stream data, and posting
     <em>all</em> live variables to a statsd server.
    <h4>More information</H4>
    ]]))

s = m:section(TypedSection, "general", _("Configuration"))
s.anonymous = true
s:option(Flag, "enabled", _("Enable this output service"),
        _([[The service will not start until this is checked]]))
s:option(Value, "statsd_host", _("The StatsD server hostname"),
	_([[Hostname of StatsD server to post to]]))
s:option(Value, "statsd_port", _("The StatsD listen port"),
	_([[Normally standard]]))

return m
