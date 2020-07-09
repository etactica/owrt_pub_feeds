--[[
 testing how cabinets with grouped breakers are handled
 Goal is that energy for instance appears as a sum across the group,
 but current/volt/pf for instance are kept per channel.
 ]]
require("busted")
local pl = require("pl.import_into")()

local TESTDATA = "spec/channel-groups-sums.testdata"

local function noit() end
local function nodescribe() end

-- We need insulate because we didn't really make a proper module
insulate("handling grouped breakers: ", function()
	local m
	setup(function()
		m = require("remake.output-dexma-core")
		m.init({verbose=7,
				cafile="blah",
				key=TESTDATA, -- any file is ok
				key_is_file=true,
		})
		local data, err = pl.data.read(TESTDATA, {delim=" ", fieldnames={"topic", "msg"}, last_field_collect=true})
		for i,v in ipairs(data) do
			m.on_message(i, v[1], v[2], 1, false)
		end
	end)

	it("sums three phase breakers on bars", function()
		-- well, so far, we've got the _state_ ok, but with multiple copies of certain datas.  I guess a "coalesce()" would just always sum repeated?
		-- any other operations expected?
		local remaining = pl.tablex.values(m._state.qd)
		local proposed = remaining[1]
		--print("BEFORE COALESCE: ", pl.pretty.write(proposed))
		proposed = m.coalesce(proposed)
		--print("AFTER COALESCE: ", pl.pretty.write(proposed))

		local expected = {
			sqn = 2,
			ts = "2020-02-27T15:16:00Z",
			values = {
				{
					p = 402,
					-- We expect this to be the _sum_ of each of the values.
					v = 2.188405344
				}
			},
			did = "thedesk-bMixed.3"
		}
		local found, match = pl.tablex.find_if(proposed.values, function(ele, arg)
			if ele.did == arg then return ele end
		end, "thedesk-bMixed.3")
		assert.truthy(found, "Should have found our three phase bar breaker")
		assert.are.same(expected, match)
	end)

	it("merges different parameter types", function()
		local remaining = pl.tablex.values(m._state.qd)
		local proposed = m.coalesce(remaining[1])

		local expected = {
			sqn = 2,
			ts = "2020-02-27T15:16:00Z",
			-- we're expecting to see two entries here, not just one
			values = {
				{
					p = 701,
					v = 0.0,
				},
				{
					p = 402,
					v = 4092.9811400000003232,
				},
			},
			did = "thedesk-MAIN Tri"
		}
		local found, match = pl.tablex.find_if(proposed.values, function(ele, arg)
			if ele.did == arg then return ele end
		end, "thedesk-MAIN Tri")
		assert.truthy(found, "Should have found our mains top level object")
		assert.are.same(expected, match)

	end)

end)


insulate("coalese can run twice", function()
	local m
	setup(function()
		m = require("remake.output-dexma-core")
		m.init({verbose=7,
				cafile="blah",
				key=TESTDATA, -- any file is ok
				key_is_file=true,
		})
		local data, err = pl.data.read(TESTDATA, {delim=" ", fieldnames={"topic", "msg"}, last_field_collect=true})
		--print("data loaded is ", data, err)
		for i,v in ipairs(data) do
			local topic, msg = table.unpack(v)
			m.on_message(i, topic, msg, 1, false)
		end
	end)

	it("op 1", function()
		local remaining = pl.tablex.values(m._state.qd)
		local proposed = remaining[1]
		proposed = m.coalesce(proposed)
		proposed = m.coalesce(proposed)
		proposed = m.coalesce(proposed)
	end)

	it("op 2", function()
		local remaining = pl.tablex.values(m._state.qd)
		local proposed = remaining[1]
		proposed = m.coalesce(proposed)
		proposed = m.coalesce(proposed)
	end)
end)
