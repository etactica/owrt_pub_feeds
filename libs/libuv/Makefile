#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libuv
PKG_VERSION:=0.11.29
PKG_RELEASE:=1
PKG_REV:=v$(PKG_VERSION)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=git://github.com/joyent/libuv.git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_LICENSE:=MIT
PKG_MAINTAINER:=Karl Palsson <karlp@remake.is>

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
include $(INCLUDE_DIR)/package.mk

CONFIGURE_ARGS+=--disable-dtrace

define Package/libuv
  SECTION:=libs
  CATEGORY:=Libraries
  URL:=https://github.com/joyent/libuv
  TITLE:=Cross-platform asychronous I/O
  DEPENDS:=+libpthread +librt
endef

define Package/libuv/description
  libuv is a multi-platform support library with a focus on asynchronous I/O.
It was primarily developed for use by Node.js, but it's also used by Mozilla's
Rust language, Luvit, Julia, pyuv, and others.
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	echo "m4_define([UV_EXTRA_AUTOMAKE_FLAGS], [])" > $(PKG_BUILD_DIR)/m4/libuv-extra-automake-flags.m4
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/* $(1)/usr/lib/
endef

# This installs files on the target.  Compare with Build/InstallDev
define Package/libuv/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/libuv.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libuv))

