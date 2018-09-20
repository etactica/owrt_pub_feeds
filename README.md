Public feeds for OpenWRT.

These are maintained for two purposes:
1. Develop new or alternate packages prior to upstream inclusion
2. Provide updates to packages when upstream has frozen or moved on

In other words, there are two sorts of packages here. Firstly, immature,
untested, possibly even unused packages.  And secondly, well tested packages
for older builds.

Current OpenWrt releases and their status
* Backfire (10.03) All packages should still work, but no longer tested.
  Support and workarounds have not been dropped.
* Attitude Adjustment (12.09) As Backfire
* Barrier Breaker (14.07) As Backfire
* Chaos Calmer (15.05) Should work without issues
* Master/Trunk Should work without issues.

Note that there _are_ duplicate packages here! Some packages are also available
upstream, with exactly the same version, simply with less old release backage.

*NOTE*: This is only a feed, ie, recipes for building.  This does not include
binaries for any architecture, for any release.

Howto
=====
1. Add this to your feeds.conf

   src-git owrt_pub_feeds git://github.com/remakeelectric/owrt_pub_feeds.git

   or

   src-link owrt_pub_feeds /where/you/cloned/this/repo

   or

   src-git owrt_pub_feeds git://github.com/remakeelectric/owrt_pub_feeds.git;branch_xx


2. ./scripts/feeds update owrt_pub_feeds
3. ./scripts/feeds install -p owrt_pub_feeds -a
4. make menuconfig and choose the new packages :)

Known issues
============

If any of the packages in this feed are already in the upstream feed, you
may have problems where running "update" keeps building the same (old)
version.  This is a common problem for the _mosquitto_ package.
The OpenWrt build system sees it already has a definition for
the mosquitto package installed, from the upstream feed, and only checks
_that_ feed for updates.  The workaround is to uninstall the problem
package, and reinstall it, preferentially from the desired feed.

1. ./scripts/feeds uninstall mosquitto
2. ./scripts/feeds install -p owrt_pub_feeds mosquitto

See also the github issues

"Abandoned" packages
====================

Perhaps not abandonded, but the following packages have been merged upstream,
and will no longer be worked on here.  They remain purely for people who may
wish to use them with older versions, but they should NOT be considered the
right source!

* luci-app-pagekitec - merged to luci core for 18.06 and later
* luci-app-mosquitto - merged to luci core _after_ 18.06
* pagekitec - merged to openwrt-packages for 18.06 and later
* mosquitto - has been in openwrt-packages for a long time
* mosquitto-next only ever for experimental packages
* lua-penlight has been in openwrt-packages since 15.05
* lua-mosquitto has been in openwrt-packages since 15.05
* lpeg has been in openwrt-packages since at least 15.05
* libev has been in openwrt-packages since at least 15.05
* libevent21 libevent2 was updated to v2.1 in openwrt-core _after_ 18.06

Experimental packages
=====================

Experiments, prerequisites for experiments, or otherwise unsuitable for upstreaming:

Everything else :)
