--[[
-- LuCI model page for the basic configuration of the output module
-- Copyright Karl Palsson <karlp@etactica.com> June 2017
-- Licensed under your choice of Apache2, ISC, MIT, or BSD 2 clause
--]]

m = Map("output-dexma", "Message Output Daemon - Dexma",
  [[This service handles parsing the eTactica live stream data, and posting it to your DEXCell account.
 <h4>Before you start</h4>
  You should have created a virtual gateway, and obtained your gateway Identifier/Token security pairs.
   Please see the following Dexma guides on setting these up
   <ul>
   <li><a href="http://support.dexmatech.com/customer/portal/articles/372837-howto-add-and-configure-a-virtual-gateway">Create a virtual gateway</a>
   <li><a href="http://support.dexmatech.com/customer/portal/articles/1745489-howto-obtain-mac-and-token-from-a-gateway">Obtain gateway ID/Token</a>
   </ul>
   <h4>About Dexma <img src="/resources/images/dexma.png" width="51" height="42" style="vertical-align: middle"/></h4>
   From their website:
   <blockquote>
   DEXMA provides flexible, cost-effective and integrated software and hardware tools that enable full
   visibility of energy consumption and costs. Our intelligent energy management suite, DEXCell Energy Manager,
   is cloud-based and hardware-neutral. It combines advanced monitoring, analysis, alerts and reporting in an easy-to-use SaaS solution.
   </blockquote>
   <a href="http://www.dexmatech.com/software/" target="_blank">Visit their site for more information</a>
 ]])

s = m:section(TypedSection, "general", "Configuration")
s.anonymous = true
s:option(Flag, "enabled", "Enable this output service",
        [[The service will not start until this is checked]])
s:option(Value, "source_key", "ID for your stream",
	[[Is the Identifier (MAC address) of the gateway or the unique key that identifies the datasource which the data belongs to]])
s:option(Value, "dexcell_source_token", "The authentication token for every gateway",
	[[Aka, password. this is required to be able to publish to the stream]])

return m
