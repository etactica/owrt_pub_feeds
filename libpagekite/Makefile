#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libpagekite
PKG_REV:=3835e8d4a832496ca131a8fd3f6f00cd02fc2a18
PKG_VERSION:=0.1-$(PKG_REV)
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

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/pagekite $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
