#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=pagekitec
PKG_REV:=81c9d8913d740b8f0034b53f03238ac94ad5fe1e
PKG_VERSION:=121207C-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=git@github.com:pagekite/libpagekite.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
# jow says also try PKG_SOURCE_VERSION:=origin/branchname... (gets HEAD?)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Make localhost servers publicly visible.
  URL:=https://pagekite.net/wiki/Floss/LibPageKite/
  DEPENDS:=+libopenssl +libpthread +libev
endef

define Package/$(PKG_NAME)/description
PageKite is a system for running publicly visible servers (generally
 web servers) on machines without a direct connection to the Internet,
 such as mobile devices or computers behind restrictive firewalls.
 PageKite works around NAT, firewalls and IP-address limitations by
 using a combination of tunnels and reverse proxies.
 .
 This package provides an implementation of the PageKite Protocol in C,
 optimized for high-performance or embedded applications.
 .
 Basic UCI support for HTTP and SSH servers is also included in this package.
 .
 https://pagekite.net/wiki/Floss/LibPageKite/
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/pagekite
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/pagekite $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/pagekite.init $(1)/etc/init.d/pagekite
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/pagekite.config $(1)/etc/config/pagekite
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/pagekite.uci-defaults $(1)/etc/uci-defaults/pagekite
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
