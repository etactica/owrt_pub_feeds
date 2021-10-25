--[[ At least some basic sanity on the https client ]]
require("busted")
local m = require("remake.output-dexma-core")

local ENDPOINT = "localhost:8912/"
local BASE = "https://" .. ENDPOINT

describe("Basic sanity of HTTPS client code: #integ", function()
	it("handles normal case", function()
		local a, b, c = m.httppost(BASE .. "dexma", {dummy=123}, {["x-dexcell-source-token"] = "mysecret" }, {verify={}})
		assert.is.truthy(a, b)
		assert.are.equal(200, b)
	end)

	it("handles 500", function()
		local a, b, c = m.httppost(BASE .. "makeerror/500", {dummy=123}, nil,{verify={}})
		assert.is.truthy(a, b)
		assert.are.equal(500, b)
	end)
	it("handles 404", function()
		local a, b, c = m.httppost(BASE .. "makeerror/404", {dummy=123}, nil,{verify={}})
		assert.is.truthy(a, b)
		assert.are.equal(404, b)
	end)
	it("http isn't accepted!", function()
		local a, b, c = m.httppost("http://" .. ENDPOINT .. "dexma", {dummy=123}, {verify={}})
		assert.is.falsy(a, b)
	end)
	it("ignores invalid url", function()
		local a, b, c = m.httppost("scptasdfsd://blahblah.example.org/asdfads", {dummy=123}, nil,{verify={}})
		assert.is.falsy(a, b)
	end)
end)