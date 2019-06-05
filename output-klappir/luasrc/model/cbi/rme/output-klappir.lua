--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> Sept 2018
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]
local _ = luci.i18n.translate

m = Map("output-klappir", _("Message Output Daemon - Klappir"),
    _([[This service handles bridging eTactica live stream data, and posting it to your Klappir account.
    <h4>Before you start</h4>
    You should <em>already</em> have a Klappir account.
    <h4>More information</H4>
    <p/>
    From their website:
    <blockquote>
    Capture operational data, calculate your environmental footprint and ensure compliance to regulations.
    </blockquote>
    <p/>
    <a href="https://klappir.com/" target="_blank">
        <img src="/resources/images/klappir-logo.png" height="31" style="vertical-align: middle" alt="klappir logo"/><br>
        Visit their site for more information
    </a>
    </p>
    ]]))

s = m:section(TypedSection, "general", _("Configuration"))
s.anonymous = true
s:option(Flag, "enabled", _("Enable this output service"),
        _([[The service will not start until this is checked]]))
s:option(Value, "username", _("The MQTT bridge username"),
	_([[Provided by Klappir, unique for your account]]))
s:option(Value, "address", _("The MQTT broker address"),
	_([[Provided by Klappir, normally standard]]))

return m
