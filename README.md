Public feeds for OpenWRT.

Eventually these all desire to move upstream, but they start here
* Primarily tested with backfire 10.03
* Testing underway with Attitude Adjustment (trunk)

Note: This is only a feed, ie, recipes for building.  This does not include
binaries for any architecture, for any release.

Howto
=====
1. Add this to your feeds.conf

   src-git owrt_pub_feeds git://github.com/remakeelectric/owrt_pub_feeds.git

   or

   src-link owrt_pub_feeds /where/you/cloned/this/repo

2. ./scripts/feeds/update owrt_pub_feeds
3. ./scripts/feeds/install -p owrt_pub_feeds -a
4. make menuconfig and choose the new packages :)

Known issues
============

pagekite and in particular socksipychain have some issues with dependencies
that are normally resolved by rebuilding.  Help wanted?

