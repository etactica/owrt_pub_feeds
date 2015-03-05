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
-- Example: ugly_log.notice("Got id %s from request, if id is nil is okay", tostring(id)) 
--
-- Two kinds of logging are supported:
-- Logging with format string and logging with callback. See details at the bottom
--
-- Example for initialization:
-- Set application id and desired threshold
-- (here all log messages with higher and equal priority than "warning" are logged)
-- initialize("alert_mq_client", "warning")
--
-- Examples for logging methods (format string)
-- warning("Only %d space left on disk", space_left)
-- info("Writing %s to file %s", result, output)
--]]

module(..., package.seeall)

local function load_module_if_available(module_name)
    local status, module = pcall(require, module_name)
    return status and module or nil
end

local syslog = load_module_if_available("syslog")
local posix = load_module_if_available("posix")
local nixio = load_module_if_available("nixio")

-- not all fancy modules available in the current environment? Just use console!
local is_environment_complete = syslog and posix and nixio

local default_threshold_logging_level = 5
local default_application_id = "Lua Application"

-- notice is default
local threshold_logging_level = default_threshold_logging_level
local application_id = default_application_id
local is_daemon = false

-- corresponding to enum in syslog.h
local levels = { emerg=0, alert=1, crit=2, err=3, warning=4, notice=5, info=6, debug=7 }

-- accept both numbers and strings
local function set_logging_level(logging_level)
    if type(logging_level) == "number" and
        logging_level >= 0 and
        logging_level <= 7 then
        threshold_logging_level = logging_level
    elseif levels[logging_level] then
        threshold_logging_level = levels[logging_level]
    else
        threshold_logging_level = default_threshold_logging_level
    end
end

local function repair_log(log, ...)
    -- something went wrong, print out what you can print out!
    repaired_output = {}
    repaired_output[1] = "(FIXED LOG)"
    i = 2
    for k,v in pairs({...}) do
        -- print index
        repaired_output[i] = "("
        i = i + 1
        repaired_output[i] = tostring(k)
        i = i + 1
        repaired_output[i] = ")"
        i = i + 1
        -- print value
        repaired_output[i] = tostring(v)
        i = i + 1
    end
    log(table.concat(repaired_output, " "))
end

local function innerlog_c(log_level, log_level_number, callback, ...)
    if (log_level_number > threshold_logging_level) then
        -- do not log if not desired
        return;
    end
    local log
    -- now actually log something
    if is_environment_complete and is_daemon then
        log = function (x) syslog.syslog(log_level, x) end
    else
        log = function (x) io.stderr:write(string.format("(Simple Log)%s %s: %s\n", log_level, application_id, x)) end
    end
    -- an error during logging should not stop the application
    if pcall(callback, log, ...) then 
        return
    end
    if pcall(repair_log, log, ...) then
        return
    end
    -- this should actually never happen...
    io.stderr:write("ERROR: Broken logging!\n")
end

local function format_callback(log, format, ...)
    -- format might be nil
    local result = (format and string.format(format, ...)) or table.concat({...}," ")
    log(result)
end

local function innerlog(log_level, log_level_number, format, ...)
    innerlog_c(log_level, log_level_number, format_callback, format, ...)
end

-- logging level might be a string ("emerg", "info" etc.) or a number in the range 0 to 7 or nil
function initialize(application_name, logging_level)
    application_id = application_name or default_application_id
    set_logging_level(logging_level)
    if not is_environment_complete then
        -- use console
        return
    end
    -- works on openWRT, parent id that is returned is 1 when daemon
    -- if daemon use syslog otherwise use console
    is_daemon = posix.getpid("ppid") == 1
    local options = nixio.bit.bor(syslog.LOG_PERROR, syslog.LOG_ODELAY)
    syslog.openlog(string.format("%s[%d]", application_id, posix.getpid("pid")), options, "LOG_USER")
end

-- logging with format, first argument must be a format string
-- e.g.
-- format = "Write to file %s"

function emerg(format, ...)
    innerlog("LOG_EMERG", 0, format, ...)
end

function alert(format, ...)
    innerlog("LOG_ALERT", 1, format, ...)
end

function crit(format, ...)
    innerlog("LOG_CRIT", 2, format, ...)
end

function err(format, ...)
    innerlog("LOG_ERR", 3, format, ...)
end

function warning(format, ...)
    innerlog("LOG_WARNING", 4, format, ...)
end

function notice(format, ...)
    innerlog("LOG_NOTICE", 5, format, ...)
end

function info(format, ...)
    innerlog("LOG_INFO", 6, format, ...)
end

function debug(format, ...)
    innerlog("LOG_DEBUG", 7, format, ...)
end

-- logging with callback, first argument of callback must be the output function log
-- e.g.
-- callback = function (log, my_table) for _,v in pairs(my_table) do log(tostring(v)) end end

function emerg_c(callback, ...)
    innerlog_c("LOG_EMERG", 0, callback, ...)
end

function alert_c(callback, ...)
    innerlog_c("LOG_ALERT", 1, callback, ...)
end

function crit_c(callback, ...)
    innerlog_c("LOG_CRIT", 2, callback, ...)
end

function err_c(callback, ...)
    innerlog_c("LOG_ERR", 3, callback, ...)
end

function warning_c(callback, ...)
    innerlog_c("LOG_WARNING", 4, callback, ...)
end

function notice_c(callback, ...)
    innerlog_c("LOG_NOTICE", 5, callback, ...)
end

function info_c(callback, ...)
    innerlog_c("LOG_INFO", 6, callback, ...)
end

function debug_c(callback, ...)
    innerlog_c("LOG_DEBUG", 7, callback, ...)
end
