--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> June 2017
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

local _ = luci.i18n.translate

m = Map("output-dexma", "Message Output Daemon - Dexma",
  _([[This service handles parsing the eTactica live stream data, and posting it to your DEXCell account.
 <h4>Before you start</h4>
  You should have created a virtual gateway, and obtained your gateway Identifier/Token security pairs.
   Please see the following Dexma guides on setting these up
   <ul>
   <li><a href="http://support.dexmatech.com/customer/portal/articles/372837-howto-add-and-configure-a-virtual-gateway">Create a virtual gateway</a>
   <li><a href="http://support.dexmatech.com/customer/portal/articles/1745489-howto-obtain-mac-and-token-from-a-gateway">Obtain gateway ID/Token</a>
   </ul>
   <h4>About Dexma <img src="/resources/images/dexma.png" width="156" height="65" style="vertical-align: middle"/></h4>
   From their website:
   <blockquote>
   DEXMA Energy Intelligence is a leading provider of energy management solutions for buildings in the commercial and
   industrial sectors. The 100% hardware-neutral, cloud SaaS tool - DEXMA Platform - combines Big Data analytics
   with energy efficiency to help businesses and public administration Detect, Analyse and Control energy consumption,
   become more sustainable and optimise project investment.
   </blockquote>
   <a href="http://www.dexma.com/" target="_blank">Visit their site for more information</a>
 ]]))

s = m:section(TypedSection, "general", _("Configuration"))
s.anonymous = true
s:option(Flag, "enabled", _("Enable this output service"),
        _([[The service will not start until this is checked]]))
s:option(Value, "source_key", _("ID for your stream"),
	_([[Is the Identifier (MAC address) of the gateway or the unique key that identifies the datasource which the data belongs to]]))
s:option(Value, "dexcell_source_token", _("The authentication token for every gateway"),
	_([[Aka, password. this is required to be able to publish to the stream]]))

return m
