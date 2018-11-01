--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> Sept 2018
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-fake1", "Message Output Daemon - Fake1",
    [[This service handles bridging eTactica live stream data, and posting it to your Fake1 account.
    <h4>Before you start</h4>
    You should <em>already</em> have an Fake1 account.
    <h4>More information</H4>
    <p/>
    From their website:
    <blockquote>
    hahah, this is Fake!, we install bitcoin miners in your web banners!!!1!!1!!
    </blockquote>
    <p/>
    <a href="http://fake1.example.com/">
        <img src="/resources/images/fake1.png" height="31" style="vertical-align: middle" alt="Fake1 logo"/><br>
        Visit their site for more information
    </a>
    </p>
    ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "username", "The MQTT bridge username", 
	[[Provided by Fake1, unique for your account]])
s:option(Value, "password", "The MQTT bridge password", 
	[[Provided by Fake1, unique for your account]])
s:option(Value, "address", "The MQTT broker address",
	[[Provided by Fake1, normally standard]])

return m
