#
# Copyright (C) 2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=hotplug-netlink
PKG_RELEASE:=1
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=hotplug netlink debugger
  DEPENDS:=+libc
endef

define Build/Prepare
	$(CP) ./files/* $(PKG_BUILD_DIR)/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dbg-hotplug-netlink $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
