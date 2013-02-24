--[[
LuCI - Lua Configuration Interface for pagekite

Copyright 2012 OpenWrt.org

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0


]]--

module("luci.controller.pagekitec", package.seeall)

function index()
    entry({"admin", "services", "pagekitec"}, cbi("pagekitec"), "PageKite")
end
