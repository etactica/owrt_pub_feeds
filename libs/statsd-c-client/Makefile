#
# Karl Palsson <karlp@etactica.com> March 2019
#

include $(TOPDIR)/rules.mk

PKG_NAME:=statsd-c-client
PKG_REV:=0caa5ef05d
PKG_VERSION:=1.0-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_SOURCE_URL:=https://github.com/romanbsd/statsd-c-client.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/default
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=simple statsd client library for C
  ABI_VERSION:=2.0.1
  URL:=https://github.com/romanbsd/statsd-c-client
endef

define Package/$(PKG_NAME)
    $(Package/$(PKG_NAME)/default)
endef

define Package/$(PKG_NAME)/description
The "standard" simple statsd C client library.
endef

define Build/Compile
	# Upstream makefile is not remotely portable.
	$(TARGET_CC) $(FPIC) -o $(PKG_BUILD_DIR)/libstatsdclient.so -shared $(TARGET_CFLAGS) $(PKG_BUILD_DIR)/statsd-client.c
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/statsd-client.h $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/lib
	# Not actually properly versioned.
	$(CP) $(PKG_BUILD_DIR)/libstatsdclient.so $(1)/usr/lib
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libstatsdclient.so $(1)/usr/lib
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
