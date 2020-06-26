#!/usr/bin/lua
-- Karl Palsson <karlp@etactica.com> June 2020
local json = require("cjson.safe")
local inotify = require("inotify")
local P = require("posix")
local pl = require("pl.import_into")()
local uloop = require("uloop")
uloop.init()

local ugly= require("remake.uglylog")

local args = pl.lapp [[
    Monitor a pagekite (json) status file and maintain a LED with the state of that
    connection. The LED given will be taken over for use by this process, any existing
    triggers will be replaced!

    -f,--file (default "/tmp/remake.d/et-remote.status.json") File to watch
    -l,--led (default "eg200:red:etactica") LED name in sysfs
    -v,--verbose (0..7 default 5) Logging level, higher == more
]]

local state = {
	APP_NAME = "et-remote-monitor",
}

--- Handle an et-remote status change event.
-- ev is a raw inotify event
local function handle_watch_event(cfg, ev)

	local function setled(on)
		if type(on) == "boolean" then
			local lfn = pl.path.join("/sys/class/leds", cfg.led)
			pl.file.write(pl.path.join(lfn, "trigger"), "none")
			if on then
				pl.file.write(pl.path.join(lfn, "brightness"), "255")
			else
				pl.file.write(pl.path.join(lfn, "brightness"), "0")
			end
		elseif type(on) == "table" then
			local lfn = pl.path.join("/sys/class/leds", cfg.led)
			pl.file.write(pl.path.join(lfn, "trigger"), "timer")
			if on then
				pl.file.write(pl.path.join(lfn, "delay_on"), tostring(on[1]))
			else
				pl.file.write(pl.path.join(lfn, "delay_off"), tostring(on[2]))
			end
		else
			error("Unsupported mode of led setting: " .. type(on))
		end
	end

	ugly.debug("handling inotify ev: wd: %d, mask: %d", ev.wd, ev.mask)
	local data = pl.file.read(cfg.fraw)
	if data then
		ugly.debug("gross, got some file <%s>", data)
		local msg, err = json.decode(data)
		if not msg then
			-- This means the file changed, but is garbage to us
			ugly.warning("status file was invalid json: %s", err)
			setled(false)
			return
		end
		ugly.debug("Pagekite (pid: %d) status is %s", msg.pagekitec_pid, msg.pagekitec_status)
		local pkpid = msg.pagekitec_pid
		-- ok, is the file still ok?
		local proccmdline = pl.path.join("/proc", tostring(pkpid), "cmdline")
		if not pl.path.isfile(proccmdline) then
			ugly.info("status file PID no longer live")
			setled(false)
			return
		end
		local cmdline = pl.file.read(proccmdline)
		if not cmdline:find("pagekitec") then
			ugly.info("status file PID appears unrelated")
			setled(false)
			return
		end
		if msg.pagekitec_status_code == 40 then
			ugly.info("status looks good!")
			setled(true)
		else
			ugly.info("status is unhappy: %s", msg.pagekitec_status)
			setled({50,100})
		end
	else
		-- this is how we can handle deletion notifications...
		ugly.info("status file was removed")
		setled(false)
	end
end


local function setup_watch(cfg)
	local handle = inotify.init({blocking=false})
	local wd_path, err2 = handle:addwatch(cfg.fpath,
			inotify.IN_MODIFY,
			inotify.IN_CLOSE_WRITE,
			inotify.IN_DELETE,
			inotify.IN_MOVE)
	if not wd_path then
		error(string.format("Unable to watch path: %s for file changes: %s", cfg.fpath, err2))
	end

	local function innerreal(ufd, events)
		for ev in ufd:events() do
			if ev.wd == wd_path and ev.name == cfg.fname then
				handle_watch_event(cfg, ev)
			end
		end
	end

	-- handle it once as the file might have already been created
	handle_watch_event(cfg, {wd=0, mask=0})

	-- ensure handle does not go out of scope
	state.fs_watcher = uloop.fd_add(handle, innerreal, uloop.ULOOP_READ)
end

local function main()
	ugly.initialize(state.APP_NAME, args.verbose or 4)

	-- inotify can't watch for a file to be created, you need to watch the
	-- directory, and _then_ watch the file for changes if needed!
	state.fpath, state.fname = pl.path.splitpath(args.file)
	state.fraw = args.file
	state.led = args.led

	if not pl.path.isdir(state.fpath) then
		ugly.err("File path provided doesn't exist: %s", state.fpath)
		return 1
	end

	if not pl.path.isdir(pl.path.join("/sys/class/leds", args.led)) then
		ugly.err("LED not found in /sys/class/leds: %s", args.led)
		return 2
	end

	local function sig_handler(signo)
		ugly.debug("Graceful exit handling signal: ", signo)
		uloop.cancel()
	end
	P.signal(P.SIGINT, sig_handler)
	-- Required hoops to allow the signal handler to work, with a latency of up to XXXms
	local interrupt_timer
	interrupt_timer = uloop.timer(function() interrupt_timer:set(500) end, 500)

	setup_watch(state)
	ugly.notice("Monitoring %s, for LED: %s", state.fraw,state.led)
	uloop.run()
end

main()