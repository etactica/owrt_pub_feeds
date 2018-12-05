--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> Sept 2018
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-klappir", "Message Output Daemon - Klappir",
    [[This service handles bridging eTactica live stream data, and posting it to your Klappir account.
    <h4>Before you start</h4>
    You should <em>already</em> have a Klappir account.
    <h4>More information</H4>
    <p/>
    From their website:
    <blockquote>
    Capture operational data, calculate your environmental footprint and ensure compliance to regulations.
    </blockquote>
    <p/>
    <a href="https://klappir.com/">
        <img src="/resources/images/klappir-logo.png" height="31" style="vertical-align: middle" alt="klappir logo"/><br>
        Visit their site for more information
    </a>
    </p>
    ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "username", "The MQTT bridge username", 
	[[Provided by Klappir, unique for your account]])
s:option(Value, "address", "The MQTT broker address",
	[[Provided by Klappir, normally standard]])

return m
