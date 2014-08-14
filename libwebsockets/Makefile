#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=libwebsockets

PKG_VERSION:=1.3-chrome37-firefox30
PKG_RELEASE:=1
PKG_SOURCE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/warmcat/$(PKG_NAME)/archive/
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_SOURCE_SUBDIR)

CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS += $(if $(CONFIG_PACKAGE_kmod-ipv6),,-DLWS_IPV6=)

CMAKE_OPTIONS += -DLWS_WITHOUT_TESTAPPS=$(if $(CONFIG_PACKAGE_libwebsockets-examples),"OFF","ON")

# other options worth noting
# CMAKE_OPTIONS += -DLWS_WITHOUT_EXTENSIONS=ON
# CMAKE_OPTIONS += -DLWS_WITHOUT_DAEMONIZE=ON
# CMAKE_OPTIONS += -DLWS_WITHOUT_SERVER=ON
# CMAKE_OPTIONS += -DLWS_WITHOUT_DEBUG=ON


define Package/$(PKG_NAME)/Default
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=libwebsockets
	DEPENDS:=+zlib
endef

define Package/libwebsockets-openssl
	$(call Package/$(PKG_NAME)/Default)
	TITLE += (OpenSSL)
	DEPENDS += +libopenssl
	VARIANT:=openssl
endef

define Package/libwebsockets-cyassl
	$(call Package/$(PKG_NAME)/Default)
	TITLE += (CyaSSL)
	DEPENDS += +libcyassl
	VARIANT:=cyassl
endef

define Package/libwebsockets-examples
	$(call Package/libwebsockets/Default)
	DEPENDS:=libwebsockets
	TITLE+= (examples)
endef

define Package/libwebsockets-examples/description
	libwebsockets examples
	This package contains libwebsockets examples
endef


ifeq ($(BUILD_VARIANT),openssl)
    CMAKE_OPTIONS += -DLWS_OPENSSL_CLIENT_CERTS=/etc/ssl/certs
    CMAKE_OPTIONS += -DLWS_OPENSSL_SUPPORT=ON
    CMAKE_OPTIONS += -DLWS_WITH_SSL=ON
endif

ifeq ($(BUILD_VARIANT),cyassl)
    CMAKE_OPTIONS += -DLWS_OPENSSL_CLIENT_CERTS=/etc/ssl/certs
    CMAKE_OPTIONS += -DLWS_OPENSSL_SUPPORT=ON
    CMAKE_OPTIONS += -DLWS_WITH_SSL=ON
# for cyassl, edit package/libs/cyassl/Makefile to include --enable-opensslextra
# NOTE: it will compile without it, untested whether it it's needed?!
    CMAKE_OPTIONS += -DLWS_USE_CYASSL=ON
    CMAKE_OPTIONS += -DLWS_CYASSL_LIB=$(STAGING_DIR)/usr/lib/libcyassl.so
    CMAKE_OPTIONS += -DLWS_CYASSL_INCLUDE_DIRS=$(STAGING_DIR)/usr/include
endif

define Package/libwebsockets/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libwebsockets.so* $(1)/usr/lib/
endef

define Package/libwebsockets-examples/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/libwebsockets-test-client $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/libwebsockets-test-echo $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/libwebsockets-test-fraggle $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/libwebsockets-test-ping $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/libwebsockets-test-server $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/libwebsockets-test-server-extpoll $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/usr/share/libwebsockets-test-server
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/libwebsockets-test-server/favicon.ico $(1)/usr/share/libwebsockets-test-server/
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/libwebsockets-test-server/leaf.jpg $(1)/usr/share/libwebsockets-test-server/
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/libwebsockets-test-server/libwebsockets.org-logo.png $(1)/usr/share/libwebsockets-test-server/
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/libwebsockets-test-server/libwebsockets-test-server.key.pem $(1)/usr/share/libwebsockets-test-server/
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/libwebsockets-test-server/libwebsockets-test-server.pem $(1)/usr/share/libwebsockets-test-server/
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/libwebsockets-test-server/test.html $(1)/usr/share/libwebsockets-test-server/
endef
Package/$(PKG_NAME)-cyassl/install = $(Package/$(PKG_NAME)/install)
Package/$(PKG_NAME)-openssl/install = $(Package/$(PKG_NAME)/install)

$(eval $(call BuildPackage,libwebsockets-openssl))
$(eval $(call BuildPackage,libwebsockets-cyassl))
$(eval $(call BuildPackage,libwebsockets-examples))
