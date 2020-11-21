local json = require("cjson")
local pl = require("pl.import_into")()
require("busted")
local osapp = require("remake.output-statsd-app")

--[[
Methods for testing that we are creating the correct metrics.
much much simpler and safer than testing with live data and grpahite all the time
--]]

function noit() end
function nodescribe() end

local model_generic_meter = json.decode([[
{"deviceid":"8C944757E090","type":"profile","version":0.3,
"branches":[{"points":[{"phase":1,"reading":0},{"phase":2,"reading":1},{"phase":3,"reading":2}],
"ampsize":63,"label":"mains"}],"validated":true,"cabinet":"office"}
]])

local model_12x1ph = json.decode([[
{"deviceid":"116D504B6055","type":"profile","version":0.3,"branches":[
{"points":[{"phase":1,"reading":0}],"ampsize":16,"label":"lights.1"},{"points":[{"phase":2,"reading":1}],"ampsize":16,"label":"lights.2"},
{"points":[{"phase":3,"reading":2}],"ampsize":16,"label":"lights.3"},{"points":[{"phase":1,"reading":3}],"ampsize":16,"label":"lights.4"},
{"points":[{"phase":2,"reading":4}],"ampsize":16,"label":"lights.5"},{"points":[{"phase":3,"reading":5}],"ampsize":16,"label":"lights.6"},
{"points":[{"phase":1,"reading":6}],"ampsize":16,"label":"lights.7"},{"points":[{"phase":2,"reading":7}],"ampsize":16,"label":"lights.8"},
{"points":[{"phase":3,"reading":8}],"ampsize":16,"label":"lights.9"},{"points":[{"phase":1,"reading":9}],"ampsize":16,"label":"lights.10"},
{"points":[{"phase":2,"reading":10}],"ampsize":16,"label":"lights.11"},{"points":[{"phase":3,"reading":11}],"ampsize":16,"label":"lights.12"}
],"validated":true,"cabinet":"office"}
]])

local reading_generic_meter = json.decode([[
{ "timestamp_ms": 1605880449217, "deviceid": "8C944757E090", "readings": {
    "frequency": 50.0,
    "cumulative_wh": 0.0,
    "cumulative_varh": 0.0,
    "current\/1": 12.345000000000001, "volt\/1": 230.0, "pf\/1": 1.0,
    "current\/2": 12.345000000000001, "volt\/2": 230.0, "pf\/2": 1.0,
    "current\/3": 12.345000000000001, "volt\/3": 230.0, "pf\/3": 1.0,
    "temp": 0.0
   }, "hwc": { "slaveId": 144, "mbDevice": "local", "lastPollTime": 1605880449217,
   "deviceid": "8C944757E090", "vendor": 21069, "product": 18252,
   "vendorName": "eTactica", "pluginName": "etactica_em.lua", "pluginSource": "system",
   "pluginCategory": "electricity", "typeOfMeasurementPoints": "generic",
   "numberOfMeasurementPoints": 3, "firmwareVersion": { "major": 0, "minor": 0, "dirty": false } } }
]])

local expected_metrics_generic_meter_no_model = {
    "8C944757E090.cumulative_varh",
    "8C944757E090.cumulative_wh",
    "8C944757E090.current.1",
    "8C944757E090.current.2",
    "8C944757E090.current.3",
    "8C944757E090.frequency",
    "8C944757E090.pf.1",
    "8C944757E090.pf.2",
    "8C944757E090.pf.3",
    "8C944757E090.temp",
    "8C944757E090.volt.1",
    "8C944757E090.volt.2",
    "8C944757E090.volt.3"
}

local expected_metrics_generic_meter_with_model = {
  "office.8C944757E090.frequency",
  "office.8C944757E090.temp",
  "office.mains.cumulative_varh",
  "office.mains.cumulative_wh",
  "office.mains.current.1",
  "office.mains.current.2",
  "office.mains.current.3",
  "office.mains.pf.1",
  "office.mains.pf.2",
  "office.mains.pf.3",
  "office.mains.volt.1",
  "office.mains.volt.2",
  "office.mains.volt.3"
}

-- FIXME - Actually, horrible examples of "non-electric, will have to do better...
local model_non_electric = json.decode([[
{"deviceid":"Fake-Alpitronic-Hypercharger-0b","type":"profile","version":0.3,"branches":[
{"points":[{"phase":1,"reading":0},{"phase":2,"reading":1},{"phase":3,"reading":2}
],"ampsize":16,"label":"Charger11"}],"validated":true,"cabinet":"charging deck"}
]])

local reading_generic_non_electric = json.decode([[
{ "timestamp_ms": 1605883687857, "deviceid": "Fake-Alpitronic-Hypercharger-0b",
"readings":
    { "state": 3, "power": 103806 },
 "hwc": { "slaveId": 11, "mbDevice": "local", "lastPollTime": 1605883687857, "deviceid": "Fake-Alpitronic-Hypercharger-0b",
  "vendorName": "Alpitronic", "productName": "Hypercharger", "pluginName": "alpitronic-hypercharger.lua",
  "pluginSource": "system", "pluginCategory": "electricity", "typeOfMeasurementPoints": "generic",
  "numberOfMeasurementPoints": 3, "firmwareVersion": { "major": 0, "minor": 0, "dirty": false }
 }
}
]])

local expected_metrics_non_electric_nomodel = {
  "Fake-Alpitronic-Hypercharger-0b.power",
  "Fake-Alpitronic-Hypercharger-0b.state"
}

local expected_metrics_non_electric_with_model = {
    "charging deck.Charger11.power",
    "charging deck.Charger11.state",
}


local reading_powerbar = json.decode([[
{ "timestamp_ms": 1605883526547, "deviceid": "116D504B6055", "readings": {
     "temp": 40.0, "frequency": 49.981999999999999, "current\/1": 3.5550000000000002, "pf\/1": 1.0, "wh_in\/1": 11.0, "volt\/1": 228.26300000000001,
     "current\/2": 0.0, "pf\/2": 1.0, "wh_in\/2": 22.0, "volt\/2": 228.26300000000001, "current\/3": 0.45700000000000002, "pf\/3": 1.0,
     "wh_in\/3": 33.0, "volt\/3": 228.26300000000001, "current\/4": 0.0, "pf\/4": 1.0, "wh_in\/4": 44.0, "volt\/4": 228.26300000000001,
     "current\/5": 0.46999999999999997, "pf\/5": 1.0, "wh_in\/5": 55.0, "volt\/5": 228.26300000000001, "current\/6": 0.47799999999999998,
     "pf\/6": 1.0, "wh_in\/6": 66.0, "volt\/6": 228.26300000000001, "current\/7": 0.0, "pf\/7": 1.0, "wh_in\/7": 77.0, "volt\/7": 228.26300000000001,
     "current\/8": 0.0, "pf\/8": 1.0, "wh_in\/8": 88.0, "volt\/8": 228.26300000000001, "current\/9": 0.074999999999999997, "pf\/9": 1.0,
     "wh_in\/9": 99.0, "volt\/9": 228.26300000000001, "current\/10": 0.11600000000000001, "pf\/10": 1.0, "wh_in\/10": 1010.0, "volt\/10": 228.26300000000001,
     "current\/11": 0.0, "pf\/11": 1.0, "wh_in\/11": 1111.0, "volt\/11": 228.26300000000001, "current\/12": 0.050000000000000003, "pf\/12": 1.0,
     "wh_in\/12": 1212.0, "volt\/12": 228.26300000000001
 },
 "hwc": { "slaveId": 85, "mbDevice": "local", "lastPollTime": 1605883526547, "deviceid": "116D504B6055", "vendor": 21069,
     "product": 16972, "vendorName": "eTactica", "pluginName": "etactica_eb-es.lua", "pluginSource": "system",
     "pluginCategory": "electricity", "typeOfMeasurementPoints": "generic", "numberOfMeasurementPoints": 12,
     "firmwareVersion": { "major": 4, "minor": 14, "dirty": false }
 }
}
]])

local expected_metrics_powerbar_nomodel = {
  "116D504B6055.current.1",
  "116D504B6055.current.10",
  "116D504B6055.current.11",
  "116D504B6055.current.12",
  "116D504B6055.current.2",
  "116D504B6055.current.3",
  "116D504B6055.current.4",
  "116D504B6055.current.5",
  "116D504B6055.current.6",
  "116D504B6055.current.7",
  "116D504B6055.current.8",
  "116D504B6055.current.9",
  "116D504B6055.frequency",
  "116D504B6055.pf.1",
  "116D504B6055.pf.10",
  "116D504B6055.pf.11",
  "116D504B6055.pf.12",
  "116D504B6055.pf.2",
  "116D504B6055.pf.3",
  "116D504B6055.pf.4",
  "116D504B6055.pf.5",
  "116D504B6055.pf.6",
  "116D504B6055.pf.7",
  "116D504B6055.pf.8",
  "116D504B6055.pf.9",
  "116D504B6055.temp",
  "116D504B6055.volt.1",
  "116D504B6055.volt.10",
  "116D504B6055.volt.11",
  "116D504B6055.volt.12",
  "116D504B6055.volt.2",
  "116D504B6055.volt.3",
  "116D504B6055.volt.4",
  "116D504B6055.volt.5",
  "116D504B6055.volt.6",
  "116D504B6055.volt.7",
  "116D504B6055.volt.8",
  "116D504B6055.volt.9",
  "116D504B6055.wh_in.1",
  "116D504B6055.wh_in.10",
  "116D504B6055.wh_in.11",
  "116D504B6055.wh_in.12",
  "116D504B6055.wh_in.2",
  "116D504B6055.wh_in.3",
  "116D504B6055.wh_in.4",
  "116D504B6055.wh_in.5",
  "116D504B6055.wh_in.6",
  "116D504B6055.wh_in.7",
  "116D504B6055.wh_in.8",
  "116D504B6055.wh_in.9"
}

local expected_metrics_powerbar_withmodel = {
    -- wh_in converted to cumulative_wh
    -- freq/temp assigned to cabinet.devid...
  "office.116D504B6055.frequency",
  "office.116D504B6055.temp",
  "office.lights.1.cumulative_wh",
  "office.lights.1.current.1",
  "office.lights.1.pf.1",
  "office.lights.1.volt.1",
  "office.lights.10.cumulative_wh",
  "office.lights.10.current.1",
  "office.lights.10.pf.1",
  "office.lights.10.volt.1",
  "office.lights.11.cumulative_wh",
  "office.lights.11.current.2",
  "office.lights.11.pf.2",
  "office.lights.11.volt.2",
  "office.lights.12.cumulative_wh",
  "office.lights.12.current.3",
  "office.lights.12.pf.3",
  "office.lights.12.volt.3",
  "office.lights.2.cumulative_wh",
  "office.lights.2.current.2",
  "office.lights.2.pf.2",
  "office.lights.2.volt.2",
  "office.lights.3.cumulative_wh",
  "office.lights.3.current.3",
  "office.lights.3.pf.3",
  "office.lights.3.volt.3",
  "office.lights.4.cumulative_wh",
  "office.lights.4.current.1",
  "office.lights.4.pf.1",
  "office.lights.4.volt.1",
  "office.lights.5.cumulative_wh",
  "office.lights.5.current.2",
  "office.lights.5.pf.2",
  "office.lights.5.volt.2",
  "office.lights.6.cumulative_wh",
  "office.lights.6.current.3",
  "office.lights.6.pf.3",
  "office.lights.6.volt.3",
  "office.lights.7.cumulative_wh",
  "office.lights.7.current.1",
  "office.lights.7.pf.1",
  "office.lights.7.volt.1",
  "office.lights.8.cumulative_wh",
  "office.lights.8.current.2",
  "office.lights.8.pf.2",
  "office.lights.8.volt.2",
  "office.lights.9.cumulative_wh",
  "office.lights.9.current.3",
  "office.lights.9.pf.3",
  "office.lights.9.volt.3"
}

local model_partial_mixed_breakersizes = json.decode([[
{"deviceid":"116D504B6055","type":"profile","version":0.3,
"branches":[
{"points":[{"phase":1,"reading":0},{"phase":2,"reading":1},{"phase":3,"reading":2}],"ampsize":63,"label":"first3"},
{"points":[{"phase":1,"reading":3}],"ampsize":16,"label":"singleInner"},
{"points":[{"phase":2,"reading":4},{"phase":3,"reading":5},{"phase":1,"reading":6}],"ampsize":63,"label":"second3"}
],"validated":true,"cabinet":"office"}
]])

-- we have a partial model, and mixed sizes,
local expected_metrics_mixed_breakersizes = {
    "office.116D504B6055.current.10",
    "office.116D504B6055.current.11",
    "office.116D504B6055.current.12",
    "office.116D504B6055.current.8",
    "office.116D504B6055.current.9",
    "office.116D504B6055.frequency",
    "office.116D504B6055.pf.10",
    "office.116D504B6055.pf.11",
    "office.116D504B6055.pf.12",
    "office.116D504B6055.pf.8",
    "office.116D504B6055.pf.9",
    "office.116D504B6055.temp",
    "office.116D504B6055.volt.10",
    "office.116D504B6055.volt.11",
    "office.116D504B6055.volt.12",
    "office.116D504B6055.volt.8",
    "office.116D504B6055.volt.9",
    "office.116D504B6055.wh_in.10",
    "office.116D504B6055.wh_in.11",
    "office.116D504B6055.wh_in.12",
    "office.116D504B6055.wh_in.8",
    "office.116D504B6055.wh_in.9",
    -- only one energy, for the sum
    "office.first3.cumulative_wh",
    "office.first3.current.1",
    "office.first3.current.2",
    "office.first3.current.3",
    "office.first3.pf.1",
    "office.first3.pf.2",
    "office.first3.pf.3",
    "office.first3.volt.1",
    "office.first3.volt.2",
    "office.first3.volt.3",
    "office.second3.cumulative_wh",
    "office.second3.current.1",
    "office.second3.current.2",
    "office.second3.current.3",
    "office.second3.pf.1",
    "office.second3.pf.2",
    "office.second3.pf.3",
    "office.second3.volt.1",
    "office.second3.volt.2",
    "office.second3.volt.3",
    -- still only a root energy, but from a single
    "office.singleInner.cumulative_wh",
    "office.singleInner.current.1",
    "office.singleInner.pf.1",
    "office.singleInner.volt.1"
}


local stub_statsd = {
    gauges_seen = {},
    counter = function() end,
    decrement = function() end,
    histogram = function() end,
    increment = function() end,
    meter = function() end,
    timer = function() end,
}
function stub_statsd:gauge(metric,v)
    self.gauges_seen[metric] = v
end

describe("model tagging routines powerbar", function()
    -- NB! use pl.tablex.deepcopy on sample data, as the handlers _expect_ to be
    -- operating on fresh MQTT messages, and they modify the message as they work on it!

    before_each(function()
        stub_statsd.gauges_seen = {}
    end)

    it("should fallback nicely", function()
        local osd = osapp.init(nil, stub_statsd)
        osd:add_live_data(pl.tablex.deepcopy(reading_powerbar))
        local out = pl.tablex.keys(stub_statsd.gauges_seen)
        table.sort(out)
        assert.are_same(expected_metrics_powerbar_nomodel, out)
    end)
    it("use model if available", function()
        local osd = osapp.init(nil, stub_statsd)
        osd:handle_live_meta(nil, model_12x1ph)
        osd:add_live_data(pl.tablex.deepcopy(reading_powerbar))
        local out = pl.tablex.keys(stub_statsd.gauges_seen)
        table.sort(out)
        assert.are_same(expected_metrics_powerbar_withmodel, out)
    end)

    it("should handle partial and mixed 1/3 phase breakers", function()
        local osd = osapp.init(nil, stub_statsd)
        osd:handle_live_meta(nil, model_partial_mixed_breakersizes)
        osd:add_live_data(pl.tablex.deepcopy(reading_powerbar))
        local out = pl.tablex.keys(stub_statsd.gauges_seen)
        table.sort(out)
        assert.are_same(expected_metrics_mixed_breakersizes, out, "raw output was " .. pl.pretty.write(out))
        -- this time, we actually care about the values..
        -- we also care about the cumulative wh being summed properly!
        assert.equal(11+22+33, stub_statsd.gauges_seen["office.first3.cumulative_wh"])
        assert.equal(44, stub_statsd.gauges_seen["office.singleInner.cumulative_wh"])
        assert.equal(55+66+77, stub_statsd.gauges_seen["office.second3.cumulative_wh"])

    end)

end)

describe("model tagging routines simple meter", function()

    before_each(function()
        stub_statsd.gauges_seen = {}
    end)

    it("should fallback nicely", function()
        local osd = osapp.init(nil, stub_statsd)
        osd:add_live_data(pl.tablex.deepcopy(reading_generic_meter))
        local out = pl.tablex.keys(stub_statsd.gauges_seen)
        table.sort(out)
        assert.are_same(expected_metrics_generic_meter_no_model, out, pl.pretty.write(out))
    end)
    it("use model if available", function()
        local osd = osapp.init(nil, stub_statsd)
        osd:handle_live_meta(nil, model_generic_meter)
        osd:add_live_data(pl.tablex.deepcopy(reading_generic_meter))
        local out = pl.tablex.keys(stub_statsd.gauges_seen)
        table.sort(out)
        assert.are_same(expected_metrics_generic_meter_with_model, out, pl.pretty.write(out))
    end)

end)


describe("model tagging routines non-electric", function()
    before_each(function()
        stub_statsd.gauges_seen = {}
    end)

    it("should fallback nicely", function()
        local osd = osapp.init(nil, stub_statsd)
        osd:add_live_data(pl.tablex.deepcopy(reading_generic_non_electric))
        local out = pl.tablex.keys(stub_statsd.gauges_seen)
        table.sort(out)
        assert.are_same(expected_metrics_non_electric_nomodel, out)
    end)

    noit("should respect model #broken", function()
        local osd = osapp.init(nil, stub_statsd)
        osd:handle_live_meta(nil, model_non_electric)
        osd:add_live_data(pl.tablex.deepcopy(reading_generic_non_electric))
        local out = pl.tablex.keys(stub_statsd.gauges_seen)
        table.sort(out)
        assert.are_same(expected_metrics_non_electric_with_model, out)
    end)

end)
