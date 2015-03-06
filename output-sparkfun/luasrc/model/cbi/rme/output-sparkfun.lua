--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@tweak.net.au> March 2015
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-sparkfun", "Message Output Daemon - Sparkfun",
  [[This contains some basic configuration for a very simple output formatter
 that parses eTactica live stream data, and posts it to a given stream on
 <a href="https://data.sparkfun.com">data.sparkfun.com</a>.  
<p>You <em>must</em> have already created the stream online. If you haven't yet,
visit <a href="https://data.sparkfun.com/">data.sparkfun.com</a> and create one now!
The fields this service expects are, "amps", "kwh", "volts" and "pf".
<p>The current output daemon assumes a single EM mains meter, measuring only
a single phase (common residential) and sends the amps, volts, power factor,
and total cumulative kWh to the sparkfun api.
<p>Note, this should work with any "phant" api host with only minimal work.
 ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "public", "Public Key for your stream",
	[[This is the public identifier for your stream]])
s:option(Value, "key", "PRIVATE Key for your stream",
	[[Aka, password. this is required to be able to publish to the stream]])

return m
