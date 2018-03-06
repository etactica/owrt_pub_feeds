m = Map("pagekitec", "PageKite",
    [[
<p/>Note: you need a working PageKite account, or at least, your own running front end for this form to work.
Visit <a href="https://pagekite.net/home/">your account</a> to set up a name for your
router and get a secret key for the connection.
<p/><em>Note: this web configurator only supports
some very very basic uses of pagekite.</em>
]])
 
s = m:section(TypedSection, "pagekitec", "PageKite")
s.anonymous = true

p = s:option(Value, "kitename", "Kite Name")
p = s:option(Value, "kitesecret", "Kite Secret")
p.password = true
p = s:option(Flag, "static", "Static Setup",
	[[Static setup, disable FE failover and DDNS updates, set this if you are running your
	own frontend without a pagekite.me account]])

p = s:option(Flag, "simple_http", "Basic HTTP",
    [[Enable a tunnel to the local HTTP server (in most cases, this admin
site)]])
p = s:option(Flag, "simple_ssh", "Basic SSH",
    [[Enable a tunnel to the local SSH server]])

return m
