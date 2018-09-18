#
# Karl Palsson <karlp@tweak.net.au> Feb 2016
#

include $(TOPDIR)/rules.mk

PKG_REV:=d1eedac44e3c
PKG_NAME:=mqblynk
PKG_VERSION:=1.0-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_SOURCE_URL:=git@github.com:karlp/mqblynk.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_MAINTAINER:=Karl Palsson <karlp@tweak.net.au>
PKG_LICENSE:=oh dear

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
CMAKE_INSTALL:=1

define Package/$(PKG_NAME)/default
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=mqblynk - MQTT jsonpath to blynk
  DEPENDS:=+libjson-c +libjsonpath +libmosquittopp
endef

define Package/$(PKG_NAME)
    $(Package/$(PKG_NAME)/default)
endef

define Package/$(PKG_NAME)/description
 Listens to MQTT topics with json messages, uses jsonpath to select data and send to Blynk virtual pins.
 Listens to Blynk virtual pins and writes out to mqtt topics.  (no json path there, what would it mean?)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/mqblynk $(1)/usr/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
