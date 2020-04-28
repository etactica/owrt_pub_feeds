module("luci.controller.rme.et-remote", package.seeall)

function index()
    entry({"home", "wizard", "et-remote"}, view("rme/et-remote"), _("Remote Access"), 91)
end