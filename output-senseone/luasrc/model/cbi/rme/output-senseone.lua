--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> Sept 2018
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-senseone", "Message Output Daemon - SenseOne",
    [[This service handles bridging eTactica live stream data, and posting it to your SenseOne account.
    <h4>Before you start</h4>
    You should <em>already</em> have an SenseOne account.
    <h4>More information</H4>
    <p/>
    From their website:
    <blockquote>
<p>At SenseOne, our vision is to deliver IoT solutions that exceed customer’s expectations.

<p>We came to work on the Internet of Things from on the ground challenges to connect assets and systems inside commercial and industrial buildings.

<p>From a business standpoint, we have created an IoT middleware platform that is capable of reducing the lifecycle cost and effort of multiple integrations that are central to any IoT implementation.

<p>From a technical standpoint, we have focused on interoperability requirements and developed a scalable IoT middleware layer for integrating heterogeneous systems and enabling connected environments.
    </blockquote>
    <p/>
    <a href="http://www.senseonetech.com/">
        <img src="/resources/images/senseone.png" height="31" style="vertical-align: middle" alt="SenseOne logo"/><br>
        Visit their site for more information
    </a>
    </p>
    ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "username", "The MQTT bridge username", 
	[[Provided by SenseOne, unique for your account]])
s:option(Value, "password", "The MQTT bridge password", 
	[[Provided by SenseOne, unique for your account]])
s:option(Value, "address", "The MQTT broker address",
	[[Provided by SenseOne, normally standard]])

return m
