#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=paho-javascript
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/paho.javascript-$(PKG_VERSION)
PKG_SOURCE:=paho.javascript-$(PKG_VERSION).zip
PKG_SOURCE_URL:=http://download.eclipse.org/paho/1.0/
PKG_MD5SUM:=84bd2e39de4dad59da177257ed445279

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=javascript
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=paho javascript (mqtt websockets)
  URL:=http://eclipse.org/paho/
endef

define Package/$(PKG_NAME)/description
  This is a websockets client library for communicating with MQTT servers
endef

define Build/Compile
	echo "Nothing to compile, pure javascript package"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/resources/paho
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/mqttws31-min.js $(1)/www/resources/paho
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
