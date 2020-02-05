
-- uci hates being reloaded, it insistes on remembering things.
-- so we have one global damn uci, here, first, and we set it's directory.
local hatred = require("uci")
local lfs = require("lfs")
hatred.set_confdir(lfs.currentdir() .. "/spec/uci.dir/")
