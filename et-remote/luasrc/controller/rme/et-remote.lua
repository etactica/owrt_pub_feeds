module("luci.controller.rme.et-remote", package.seeall)

function index()
    entry({"home", "wizard", "et-remote"}, firstchild(), _("Remote Access"), 91)
    entry({"home", "wizard", "et-remote", "settings"}, view("rme/et-remote"), _("Settings"), 10)
    entry({"home", "wizard", "et-remote", "logread"}, view("rme/et-remote-logread"), _("Logs"), 30)
end