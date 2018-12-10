#
# Copyright (C) 2014 Karl Palsson <karlp@remake.is>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=upnpbeacon
PKG_VERSION:=0.1.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-v$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=https://gitorious.digitalstrom.org/dss-misc/upnpbeacon/-/archive/v$(PKG_VERSION)/
PKG_BUILD_DIR=$(BUILD_DIR)/$(PKG_NAME)-v$(PKG_VERSION)
PKG_HASH:=93c1e405cff96d96da2edcf49e249f2bb8fdceb4f6eed8acaf49290a718dd0f6
PKG_INSTALL:=1
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk
#PKG_BUILD_DEPENDS:= libupnp


define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  URL:=https://gitorious.digitalstrom.org/dss-misc/upnpbeacon
  TITLE:=upnpbeacon - Utility to find devices on a network
  DEPENDS:= +libuuid +libconfig +libupnp
endef

define Package/$(PKG_NAME)/description
 upnpbeacon uses libupnp to provide a basic beacon to help find devices on
a network.  This is mostly useful if your OpenWrt device is a network client,
rather than the more common case of being the network router. 

This package includes UCI support.
endef


define Package/$(PKG_NAME)/conffiles
/etc/config/upnpbeacon
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/$(PKG_NAME) $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
