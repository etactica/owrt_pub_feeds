--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> June 2017
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-activitystream", "Message Output Daemon - Activity Stream",
    [[This service handles bridging eTactica live stream data, and posting it to your Activity Stream account.
    <h4>Before you start</h4>
    You should <em>already</em> have an Activity Stream account.
    <h4>More information</H4>
    <p/>
    From their website:
    <blockquote>
    OPTIMIZE YOUR BUSINESS<br>
    Improve all aspects of operations and services with Artificial Intelligence
    </blockquote>
    <p/>
    <a href="http://www.activitystream.com/">
        <img src="/resources/images/activitystream.png" height="31" style="vertical-align: middle" alt="Activity Stream logo"/><br>
        Visit their site for more information
    </a>
    </p>
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
