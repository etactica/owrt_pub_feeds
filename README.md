Public feeds for OpenWRT.

Eventually these all desire to move upstream, but they start here
* All packages work on Attitude Adjustment
* All packages except pagekitec (libev) work with backfire 10.03
* Barrier Breaker (trunk) has not been extensively tested yet, if you find problems
  please let us know.

Note: This is only a feed, ie, recipes for building.  This does not include
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
version.  This is a common problem for the _mosquitto_ package.  What goes
wrong is that the owrt build system thinks it already has a definition for
the mosquitto package installed, from the upstream feed, and only checks
_that_ feed for any updates.  The workaround is to uninstall the problem
package, and reinstall it, preferentially from the desired feed.

1. ./scripts/feeds uninstall mosquitto
2. ./scripts/feeds install -p owrt_pub_feeds mosquitto

pagekite (python) and in particular socksipychain have some issues with dependencies that are normally resolved by rebuilding.  Help wanted?

See also the github issues
