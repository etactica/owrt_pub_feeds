Public feeds for OpenWRT (primarily tested with backfire 10.03,
but should be ok for trunk too)

Howto
=====
1. Add this to your feeds.conf

   src-git karlp_owrt_bf git://github.com/karlp/owrt_pub_feeds.git

   or

   src-link karlp_owrt_bf /where/you/cloned/this/repo

2. ./scripts/feeds/update -a
3. ./scripts/feeds/install -a
4. make menuconfig and choose the new packages :)

