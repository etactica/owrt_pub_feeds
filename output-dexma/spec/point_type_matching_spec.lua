require("busted")
local m = require("remake.output-dexma-core")

local DEXMA_KEYS = {
	{un="cumulative_wh", dt="cumulative_wh", n=1e-3, f="max", di=402},
	{un="cumulative_varh", dt="cumulative_varh", n=1e-3, f="max", di=404},
	{un="voltage_mean", dt="volt", f="mean", di=405},
	{un="current_max", dt="current", f="max", di=425},
	{un="current_mean", dt="current", f="mean", di=426},
	{un="pulse_count", dt="pulse_count", f="max", di=502},
	{un="temp", dt="temp", f="mean", di=701},
	{un="pf", dt="pf", f="mean", di=412},
	{un="customXXX", dt="current", f="stddev", di=999},
}

describe("Check that datapoint type <-> dexma type mappings work properly", function()
	it("handles simple single match case", function()
		local dkos, reason = m._find_datatypes("temp", DEXMA_KEYS, {"temp"})
		assert.is.truthy(dkos)
		assert.are.equal(1, #dkos)
		assert.are.same(dkos[1], {un="temp", dt="temp", f="mean", di=701})
	end)
	it("handles simple, yet real issues", function()
		local dkos, reason = m._find_datatypes("current", DEXMA_KEYS, {"current_mean"})
		assert.is.truthy(dkos)
		assert.are.equal(1, #dkos)
		assert.are.same(dkos[1], {un="current_mean", dt="current", f="mean", di=426})
	end)
	it("Handles multiple matches", function()
		local dkos = m._find_datatypes("current", DEXMA_KEYS, {"current_mean", "current_max"})
		assert.is.truthy(dkos)
		assert.are.equal(2, #dkos)
		assert.are.same(dkos[1], {un="current_max", dt="current", f="max", di=425})
		assert.are.same(dkos[2], {un="current_mean", dt="current", f="mean", di=426})
	end)
	it("returns a reason for not found", function()
		local dkos, reason = m._find_datatypes("something garbage", DEXMA_KEYS, {"asdfads"})
		assert.is_nil(dkos)
		assert.is.truthy(reason)
	end)
end)
