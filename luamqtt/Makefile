#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luamqtt
PKG_REV:=9ded933879
PKG_VERSION:=0.1-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=git@github.com:remakeelectric/mqtt_lua.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=LuaMQTT
  URL:=http://geekscape.github.com/mqtt_lua/
  DEPENDS:=+luasocket
endef

define Package/$(PKG_NAME)/description
  LuaMQTT is a native lua client for communicating with MQTT servers
endef

define Build/Compile
	echo "Nothing to compile, pure lua package"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/lua/mqtt_library.lua $(1)/usr/lib/lua/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/lua/utility.lua $(1)/usr/lib/lua/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
