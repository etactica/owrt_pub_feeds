--#!/usr/bin/lua
--[[
--ReMake Electric, 2013
--
-- Module provides an interface to syslog
--
-- Priorities: emerg, alert, crit, err, warning, notice, info, debug
--
-- Default for application id "Lua Application", default threshold is "notice"
--
-- You MUST call initialize before any logging methods.
--
-- You should wrap nil values with tostring() - Lua version >= 5.2 only calls tostring inside 
-- string.format()
-- Example: ugly.notice("Got id %s from request, if id is nil is okay", tostring(id))
--
-- Example for initialization:
-- Set application id and desired threshold
-- (here all log messages with higher and equal priority than "warning" are logged)
-- ugly.initialize("myapp", "warning")
--
-- Examples for logging methods (format string)
-- ugly.warning("Only %d space left on disk", space_left)
-- ugly.info("Writing %s to file %s", result, output)
--]]

local M = {}

local function load_module_if_available(module_name)
    local status, module = pcall(require, module_name)
    return status and module or nil
end

local posix = load_module_if_available("posix")

-- not all fancy modules available in the current environment? Just use console!
local is_environment_complete = posix

local is_daemon = false

-- corresponding to enum in syslog.h
local levels = { emerg=0, alert=1, crit=2, err=3, warning=4, notice=5, info=6, debug=7 }
local threshold_logging_level = levels.notice

-- accept both numbers and strings
local function set_logging_level(logging_level)
    if type(logging_level) == "number" and
        logging_level >= 0 and
        logging_level <= 7 then
        threshold_logging_level = logging_level
    elseif levels[logging_level] then
        threshold_logging_level = levels[logging_level]
    else
        error("Invalid argument")
    end
end

---
-- Attempt to print what we can of the user's log
local function repair_log(log, format, ...)
    local repaired = {}               
    table.insert(repaired, string.format("(FIXED LOG) %s => ", format))           
    local i = 2
    for k,v in pairs({...}) do
        -- print the index and value as best we can
        table.insert(repaired, string.format("(%s)=>%s", tostring(k), tostring(v)))
    end                          
    log(table.concat(repaired, " "))
end

local function innerlog(log_level, log_level_number, format, ...)
    if (log_level_number > threshold_logging_level) then
        -- do not log if not desired
        return;
    end
    local log
    -- now actually log something
    if is_environment_complete and is_daemon then
        log = function (x) posix.syslog(log_level_number, x) end
    else
        log = function (x) io.stderr:write(string.format("%s %s: %s\n",
            os.date("%FT%H:%M:%S"), log_level, x)) end
    end

    local function format_callback(log, format, ...)
        -- format might be nil
        local result = (format and string.format(format, ...)) or table.concat({...}," ")
        log(result)
    end

    -- an error during logging should not stop the application
    if pcall(format_callback, log, format, ...) then
        return
    end
    if pcall(repair_log, log, format, ...) then
        return
    end
    -- this should actually never happen...
    io.stderr:write("ERROR: Broken logging!\n")
end

-- logging level might be a string ("emerg", "info" etc.) or a number in the range 0 to 7 or nil
function M.initialize(application_name, logging_level)
    local application_id = application_name or default_application_id
    set_logging_level(logging_level)
    if not is_environment_complete then
        -- use console
        return
    end
    -- works on openWRT, parent id that is returned is 1 when daemon
    -- if daemon use syslog otherwise use console
    local function pgetpid()
        local pid = posix.getpid()
        if type(pid) == "table" then
            return pid["pid"]
        else
            return pid
        end
    end

    local function pgetppid()
        local pid = posix.getpid()
        if type(pid) == "table" then
            return pid["ppid"]
        else
            return posix.getppid()
        end
    end

    is_daemon = pgetppid() == 1
    local pid = pgetpid()

    -- posix.LOG_PID only available from v33 and up.
    posix.openlog(string.format("%s[%d]", application_id, pid))
end

-- logging with format, first argument must be a format string
-- e.g.
-- format = "Write to file %s"

function M.emerg(format, ...)
    innerlog("LOG_EMERG", 0, format, ...)
end

function M.alert(format, ...)
    innerlog("LOG_ALERT", 1, format, ...)
end

function M.crit(format, ...)
    innerlog("LOG_CRIT", 2, format, ...)
end

function M.err(format, ...)
    innerlog("LOG_ERR", 3, format, ...)
end

function M.warning(format, ...)
    innerlog("LOG_WARNING", 4, format, ...)
end

function M.notice(format, ...)
    innerlog("LOG_NOTICE", 5, format, ...)
end

function M.info(format, ...)
    innerlog("LOG_INFO", 6, format, ...)
end

function M.debug(format, ...)
    innerlog("LOG_DEBUG", 7, format, ...)
end

return M
