--[[
LuCI model for pagekite configuration management
Copyright OpenWrt.org, 2012

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

]]--

m = Map("pagekite", "PageKite",
    [[
<p/>Note: you need a working PageKite account for this form to work. 
Visit <a href="https://pagekite.net/home/">your account</a> to set up a name for your
router and get a secret key for the connection.
<p/><em>Note: this web configurator only supports
some very very basic uses of pagekite.  For more complex uses, disable this
page, and edit /etc/pagekite.d/pagekite.rc directly.</em>
]])
 
s = m:section(TypedSection, "pagekite", "PageKite")
s.anonymous = true

p = s:option(Value, "kitename", "Kite Name")
p = s:option(Value, "kitesecret", "Kite Secret")

p = s:option(Flag, "simple_http", "Basic HTTP",
    [[Enable a tunnel to the local HTTP server (in most cases, this admin
site)]])
p = s:option(Flag, "simple_ssh", "Basic SSH",
    [[Enable a tunnel to the local SSH server]])

return m
