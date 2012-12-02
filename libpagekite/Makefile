#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libpagekite
PKG_REV:=03d8ef3ec8cb2e89fa51d89f9f92b57e767ce0b6
PKG_VERSION:=0.2-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=git@github.com:pagekite/libpagekite.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
# jow says also try PKG_SOURCE_VERSION:=origin/branchname... (gets HEAD?)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  CATEGORY:=Libraries
  TITLE:=libpagekite
  URL:=https://pagekite.net/wiki/Floss/LibPageKite/
  DEPENDS:=+libopenssl +libpthread +libev
endef

define Package/$(PKG_NAME)/description
  This library provides implements the PageKite Protocol in C, optimized for
high-performance or embedded applications. It includes a basic command line
client
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
