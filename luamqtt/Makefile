#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luamqtt
PKG_REV:=65ff11c73b1a12ede6f2f4b550398bcd4a249840
PKG_VERSION:=0.2-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=git://git.eclipse.org/gitroot/paho/org.eclipse.paho.mqtt.lua.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
# jow says also try PKG_SOURCE_VERSION:=origin/branchname... (gets HEAD?)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=LuaMQTT
  URL:=http://eclipse.org/paho/
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
