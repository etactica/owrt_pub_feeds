#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mosquitto-next
PKG_VERSION:=2.90
PKG_RELEASE:=1
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE.txt

PKG_REV:=1d40e443663585bd315887ec69c6bef9a833b4ad
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
#PKG_SOURCE_URL:=http://github.com/etactica/mosquitto.git
PKG_SOURCE_URL:=http://github.com/ralight/mosquitto.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
#PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

include $(INCLUDE_DIR)/version.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=mosquitto-next - an MQTT message broker
  URL:=http://www.mosquitto.org/
  MAINTAINER:=Karl Palsson <karlp@etactica.com>
  DEPENDS:= +librt +libuuid @BROKEN
  DEPENDS+= +libopenssl +wslay +cJSON
  USERID:=mosquitto=200:mosquitto=200
  PROVIDES:= mosquitto
endef

define Package/$(PKG_NAME)/description
!This is mosquitto "next" a build from the develop branch!

It has no config options, includes everything, and is _incompatible_
with regular mosquitto! don't try and build them both!

Mosquitto is an open source (BSD licensed) message broker that implements
the MQTT protocol version 3.1 and 3.1.1. MQTT provides a lightweight
method of carrying out messaging using a publish/subscribe model.

This package also includes some basic support for configuring via UCI
endef


define Package/$(PKG_NAME)-client
  SECTION:=net
  CATEGORY:=Network
  TITLE:= mosquitto-next - client tools
  URL:=http://www.mosquitto.org/
  MAINTAINER:=Karl Palsson <karlp@etactica.com>
  DEPENDS:= +librt +libuuid
  DEPENDS+= +libopenssl +wslay +cJSON
  DEPENDS+=+libcares
  DEPENDS+=+libmosquitto
  PROVIDES:=mosquitto-client
endef

define Package/$(PKG_NAME)-client/description
 Command line client tools for publishing messages to MQTT servers
and subscribing to topics.
endef

define Package/lib$(PKG_NAME)
  SECTION:=libs
  CATEGORY:=Libraries
  DEPENDS:=+libpthread +librt +libcares
  DEPENDS+= +libopenssl
  TITLE:= $(PKG_NAME) - client library
  URL:=http://www.mosquitto.org/
  MAINTAINER:=Karl Palsson <karlp@etactica.com>
  PROVIDES:=libmosquitto
endef

define Package/lib$(PKG_NAME)/description
 Library required for mosquitto's command line client tools, also for
use by any third party software that wants to communicate with a
mosquitto server.

Should be useable for communicating with any MQTT v3.1/3.1.1 compatible
server, such as IBM's RSMB, in addition to Mosquitto
endef

define Package/lib$(PKG_NAME)pp
    SECTION:=libs
    CATEGORY:=Libraries
    DEPENDS:=lib$(PKG_NAME) +libstdcpp
    TITLE:= $(PKG_NAME) - client c++ library
    PROVIDES:=libmosquittopp
endef

define Package/lib$(PKG_NAME)pp/description
 C++ Library wrapper for lib$(PKG_NAME).
endef

define Package/$(PKG_NAME)/conffiles
/etc/mosquitto/mosquitto.conf
/etc/config/mosquitto
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/mosquitto $(1)/usr/sbin/mosquitto
	$(INSTALL_DIR) $(1)/etc/mosquitto
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/mosquitto.conf $(1)/etc/mosquitto/mosquitto.conf
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/apps/mosquitto_passwd/mosquitto_passwd $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/plugins/dynamic-security/mosquitto_dynamic_security.so $(1)/usr/lib
	$(CP) ./files/* $(1)/
endef

define Package/$(PKG_NAME)-client/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/client/mosquitto_pub $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/client/mosquitto_sub $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/client/mosquitto_rr $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/apps/mosquitto_ctrl/mosquitto_ctrl $(1)/usr/bin
endef

# This installs files into ./staging_dir/. so that you can cross compile from the host
define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/include/*.h $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/lib/cpp/mosquittopp.h $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/lib/libmosquitto.so.1 $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/lib/cpp/libmosquittopp.so.1 $(1)/usr/lib/
	$(LN) libmosquitto.so.1 $(1)/usr/lib/libmosquitto.so
	$(LN) libmosquittopp.so.1 $(1)/usr/lib/libmosquittopp.so
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_BUILD_DIR)/libmosquitto.pc.in $(1)/usr/lib/pkgconfig/libmosquitto.pc
	sed -i -e "s#@CMAKE_INSTALL_PREFIX@#/usr#" \
               -e "s#@VERSION@#$(PKG_VERSION)#" \
            $(1)/usr/lib/pkgconfig/libmosquitto.pc
	$(CP) $(PKG_BUILD_DIR)/libmosquittopp.pc.in $(1)/usr/lib/pkgconfig/libmosquittopp.pc
	sed -i -e "s#@CMAKE_INSTALL_PREFIX@#/usr#" \
               -e "s#@VERSION@#$(PKG_VERSION)#" \
            $(1)/usr/lib/pkgconfig/libmosquittopp.pc
endef

# This installs files on the target.  Compare with Build/InstallDev
define Package/lib$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/libmosquitto.so.1 $(1)/usr/lib/
	$(LN) libmosquitto.so.1 $(1)/usr/lib/libmosquitto.so
endef

define Package/lib$(PKG_NAME)pp/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/cpp/libmosquittopp.so.1 $(1)/usr/lib/
	$(LN) libmosquittopp.so.1 $(1)/usr/lib/libmosquittopp.so
endef

# Applies to all...
MAKE_FLAGS += WITH_DOCS=no
MAKE_FLAGS += WITH_WEBSOCKETS=yes
TARGET_CFLAGS += -I../deps/picohttpparser

$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,lib$(PKG_NAME)))
$(eval $(call BuildPackage,lib$(PKG_NAME)pp))
$(eval $(call BuildPackage,$(PKG_NAME)-client))
