--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> Jan 2018
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-openenergi", "Message Output Daemon - Open Energi",
    [[This service handles bridging eTactica live stream data, and posting it to your Open Energi account.
    <h4>Before you start</h4>
    You should <em>already</em> have an Open Energi account.
    <h4>More information</H4>
    <p/>
    From their website:
    <blockquote>
At Open Energi, we use advanced technology and data-driven insight to radically reduce the cost of delivering and consuming power.
    </blockquote>
    <p/>
    <a href="http://www.openenergi.com/" target="_blank">
        <img src="/resources/images/OE-logo.png" height="31" style="vertical-align: middle" alt="Open Energi logo"/><br>
        Visit their site for more information
    </a>
    </p>
    ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "deviceid", "Device ID",
	[[Provided by Open Energi, identifies this device]])

-- TODO - validate that the token expiry (se=xxxx) portion is in the future!
s:option(Value, "sastoken", "SAS Token", 
	[[Provided by Open Energi, this identifies your device with the Open Energi cloud]])
s:option(Value, "address", "The MQTT broker address",
	[[Provided by Open Energi, normally standard]])


--[[
 This is functional, but pretty clunky.  Ideally, make this a nice js page that loads
 the cabinetmodel/hwc and offers a little table of all the device/points and to include/exclude them
 and assign an entity id to the ones that are included.
--]]

s = m:section(TypedSection, "entity", "Entity",
    "You can configure entities here")
s.anonymous = true
s.addremove = true

s:option(Value, "entityid", "entity id", "Entity ID for this point, eg M00569")
s:option(Value, "deviceid", "device id", "Local device id for this entity id, eg 0004A3936594")

return m
