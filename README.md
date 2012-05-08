owrt_pub_feeds
==============

Public feeds for openwrt backfire.

Howto
=====
1. Add this to your feeds.conf

src_git karlp_owrt_bf git://github.com/karlp/owrt_pub_feeds.git

2. ./scripts/feeds/update -a
3. ./scripts/feeds/install -a
4. make menuconfig and choose the new packages :)
