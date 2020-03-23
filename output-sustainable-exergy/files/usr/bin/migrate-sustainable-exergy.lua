#!/usr/bin/lua
-- Helper script to migrate Sustainable Exergy settings from
-- generic "output-db" to the customized instance

local uci = require("uci")
local pl = require("pl.import_into")()

local SOURCE
local HOST = "effizienztechnologie.de"
local DBNAME = "etactica_develey148"
--local HOST = "my-susex-db.cfsiqsznajk5.eu-west-1.rds.amazonaws.com"
--local DBNAME = "postgres"
local sname = "output-sustainable-exergy"
local instance_name = "primary"
-- This must be true in production, to avoid duplicate instances
local delete_old = true

-- Read instance configuration and merge
local x = uci.cursor()
x:foreach("output-db", "instance", function(s)
    if s.dbhost == HOST and s.dbname == DBNAME then SOURCE = s end
end)

if not SOURCE then
    print("No suitable configuration found to migrate, creating a default template")
    x:set(sname, instance_name, "instance")
    x:set(sname, instance_name, "dbhost", HOST)
    x:set(sname, instance_name, "dbname", DBNAME)
    x:commit(sname)
    return
end

print("Found a matching legacy section to migrate")
x:set(sname, instance_name, "instance")

-- We only attempt to migrate settings we _expect_ in case output-db changes
local options = {
    "enabled",
    "driver", "dbname", "dbuser", "dbpass", "dbhost", "dbport",
    "interval", "store_types", "schema_create", "interval_flush_qd", "limit_qd",
    "statsd_namespace", "statsd_host", "statsd_port",
}
for _,option in pairs(options) do
    if SOURCE[option] then
        pl.utils.printf("copying existing option: %s=<%s>\n", option, tostring(SOURCE[option]))
        x:set(sname, instance_name, option, SOURCE[option])
    end
end

x:commit(sname)

local queries = {
    "custom.%s.data.query",
    "custom.%s.metadata-insert.query",
    "custom.%s.metadata-update.query",
    "custom.%s.schema",
}
for _,ft in pairs(queries) do
    local srcf = string.format(ft, SOURCE[".name"])
    local src = "/etc/output-db/" .. srcf
    local dstf = string.format(ft, instance_name)
    local dst = "/etc/output-sustainable-exergy/" .. dstf
    local op = pl.file.copy
    if delete_old then op = pl.file.move end
    if op(src, dst) then
        pl.utils.printf("Migrated %s to %s\n", src, dst)
    else
        print("!Failed to migrate from: ", src, "to dest: ", dst)
    end
end

if delete_old then
    x:delete("output-db", SOURCE[".name"])
    x:commit("output-db")
end




