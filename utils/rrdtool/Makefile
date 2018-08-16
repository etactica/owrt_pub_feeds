#
# This Makefile is considered released into the public domain.
# Where not available, please consider it licensed under your choice of
# MIT, Apache2, BSD2clause, or ISC license.

include $(TOPDIR)/rules.mk

PKG_NAME:=rrdtool
PKG_VERSION:=1.7.0
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://oss.oetiker.ch/rrdtool/pub/
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_HASH:=f97d348935b91780f2cd80399719e20c0b91f0a23537c0a85f9ff306d4c5526b

PKG_FIXUP:=autoreconf gettext-version libtool
#PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/rrdtool/Default
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=database
  TITLE:=Round Robin Database (RRD)
  URL:=http://oss.oetiker.ch/rrdtool/
endef

define Package/librrd
$(call Package/rrdtool/Default)
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE+= library ($(PKG_VERSION))
  DEPENDS+= +glib2 +liblua
endef

define Package/rrdtool
$(call Package/rrdtool/Default)
  TITLE+= tools ($(PKG_VERSION))
  DEPENDS+= +librrd
endef

CONFIGURE_ARGS += --enable-shared=yes
CONFIGURE_ARGS += --disable-perl
CONFIGURE_ARGS += --disable-tcl
CONFIGURE_ARGS += --disable-ruby
CONFIGURE_ARGS += --disable-python
CONFIGURE_ARGS += --enable-lua
CONFIGURE_ARGS += --disable-rrdcgi
CONFIGURE_ARGS += --disable-rrd_graph
CONFIGURE_ARGS += --disable-rrd_restore
CONFIGURE_ARGS += --disable-docs
CONFIGURE_ARGS += --disable-examples

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/rrdtool-1.7
	$(CP) $(PKG_INSTALL_DIR)/usr/include/*.h $(1)/usr/include/rrdtool-1.7
	$(INSTALL_DIR) $(1)/usr/lib/rrdtool-1.7
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/librrd.{a,so*} $(1)/usr/lib/rrdtool-1.7
endef

define Package/librrd/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) -L $(PKG_INSTALL_DIR)/usr/lib/librrd.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(CP) -L $(PKG_INSTALL_DIR)/usr/lib/lua/5.1/rrd.so* $(1)/usr/lib/lua/
endef

define Package/rrdtool/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/
endef

$(eval $(call BuildPackage,librrd))
$(eval $(call BuildPackage,rrdtool))

