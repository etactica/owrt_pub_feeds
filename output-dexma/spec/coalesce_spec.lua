require("busted")
local pl = require("pl.import_into")()
ugly = require("remake.uglylog")
ugly.initialize("thistest", 7)

-- Sample of what we get when we receive duplicate messages (for whatever reason)
local test_q_store_duplicate_mains =
{
  ["2020-02-27T15:16:00Z"] = {
    sqn = 3,
    ts = "2020-02-27T15:16:00Z",
    values = {
      {
        ts = "2020-02-27T15:16:00Z",
        value = { v = 25.4, p = 701, hwid = "CAFEBABE0001-temp", },
        sqn = 3,
        did = "thedesk-MAIN Tri"
      },
      {
        ts = "2020-02-27T15:16:00Z",
        value = { v = 1023.245285, p = 402, hwid = "CAFEBABE0001-cumulative_wh", },
        sqn = 3,
        did = "thedesk-MAIN Tri"
      },
      {
        ts = "2020-02-27T15:16:00Z",
        value = { v = 25.4, p = 701, hwid = "CAFEBABE0001-temp", },
        sqn = 3,
        did = "thedesk-MAIN Tri"
      },
      {
        ts = "2020-02-27T15:16:00Z",
        value = { v = 1023.245285, p = 402, hwid = "CAFEBABE0001-cumulative_wh", },
        sqn = 3,
        did = "thedesk-MAIN Tri"
      }
    },
    retries = 0
  }
}

-- We expect this to be collapsed to a single block based on did, but not summed because same hwid on the energy
-- the internal ts values are redundant, and only used when reconstructing the blocks.
local expected_post_nosumm = {
	{
		ts = "2020-02-27T15:16:00Z",
		values = {
			{
				v = 25.4,
				p = 701
			},
			{
				v = 1023.245285,
				p = 402
			}
		},
		sqn = 3,
		did = "thedesk-MAIN Tri"
	}
}

-- we sum these because the hwids are different, for the same parameter id (p) and the same dexma id (did)
local test_q_store_sum_required = {
	["2020-02-27T15:16:00Z"] = {
		sqn = 2,
		ts = "2020-02-27T15:16:00Z",
		values = {
			{
				sqn = 2,
				ts = "2020-02-27T15:16:00Z",
				did = "thedesk-bMixed.3",
				value = {
					hwid = "CAFEBABE000B-cumulative_wh-3",
					p = 402,
					v = 0.730622396
				}
			},
			{
				sqn = 2,
				ts = "2020-02-27T15:16:00Z",
				did = "thedesk-bMixed.3",
				value = {
					hwid = "CAFEBABE000B-cumulative_wh-4",
					p = 402,
					v = 0.730792216
				}
			},
			{
				sqn = 2,
				ts = "2020-02-27T15:16:00Z",
				did = "thedesk-bMixed.3",
				value = {
					hwid = "CAFEBABE000B-cumulative_wh-5",
					p = 402,
					v = 0.726990732
				}
			}
		},
		retries = 0
	}
}

-- We expect this to be collapsed to a single block based on did, but not summed because same hwid on the energy
-- the internal ts values are redundant, and only used when reconstructing the blocks.
local expected_post_summed_bar = {
	{
		ts = "2020-02-27T15:16:00Z",
		values = {
			{
				v = 2.188405344,
				p = 402
			}
		},
		sqn = 2,
		did = "thedesk-bMixed.3"
	}
}

describe("coalescing functions", function()
	assert:set_parameter("TableFormatLevel", -1)
	it("should handle duplicate messages in the store", function()
		local m = require("remake.output-dexma-core")
		local proposed = pl.tablex.values(test_q_store_duplicate_mains)[1]
		local out = m.coalesce(proposed)
		-- strip hwid from final out
		for _,v in pairs(out.values) do
			for _,vv in pairs(v.values) do
				vv.hwid = nil
			end
		end
		assert.are.same(expected_post_nosumm, out.values)
	end)
	it("should sum properly", function()
		local m = require("remake.output-dexma-core")
		local proposed = pl.tablex.values(test_q_store_sum_required)[1]
		local out = m.coalesce(proposed)
		-- strip hwid from final out
		for _,v in pairs(out.values) do
			for _,vv in pairs(v.values) do
				vv.hwid = nil
			end
		end
		assert.are.same(expected_post_summed_bar, out.values)
	end)

	local input_already_coalesced = {
  sqn = 3,
  ts = "2020-10-30T12:00:00Z",
  values = {
    {
      sqn = 3,
      ts = "2020-10-30T12:00:00Z",
      values = {
        {
          p = 402,
          v = 560.218959654
        }
      },
      did = "LJ30-a2/1"
    },
    {
      sqn = 3,
      ts = "2020-10-30T12:00:00Z",
      values = {
        {
          p = 402,
          v = 0
        }
      },
      did = "LJ30-FAKEE"
    }
  },
  retries = 1
}
	it("should not touch already coaleseced entries", function()
		local m = require("remake.output-dexma-core")
		local out = m.coalesce(input_already_coalesced)
		assert.are.same(input_already_coalesced, out)
	end)


end)