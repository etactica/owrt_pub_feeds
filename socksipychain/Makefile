#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# Based on the deluge package makefile, as an example python package.
# Karl Palsson, 2012
#

include $(TOPDIR)/rules.mk

PKG_NAME:=SocksipyChain
PKG_VERSION:=2.0.5
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://pagekite.net/pk/src/$(PKG_SOURCE)
PKG_MD5SUM:=50dc1d72575ff97edaa38d9af4c2993e

include $(INCLUDE_DIR)/package.mk
$(call include_mk, python-package.mk)

PKG_BUILD_DEPENDS:=python

define Package/socksipychain
  SUBMENU:=Python
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Chaining support for socksipy
  URL:=https://pagekite.net/wiki/Floss/PySocksipyChain/
  DEPENDS+=+python +distribute
endef

define Package/socksipychain/description
Chaining support for socksipy

Socksipy is: A Python SOCKS client module. It provides a socket-like interface 
that supports connections to any TCP service through the use of a SOCKS4, SOCKS5 or HTTP proxy
endef

define Build/Compile
	$(call Build/Compile/PyMod,.,install --prefix=/usr --root=$(PKG_INSTALL_DIR),)
	# Make sure generated scripts try to use the right python...
	$(SED) 's,#!$(HOST_PYTHON_BIN),#!/usr/bin/$(PYTHON),' $(PKG_INSTALL_DIR)/usr/bin/*
endef

define Package/socksipychain/install
	$(INSTALL_DIR) $(1)$(PYTHON_PKG_DIR)
	$(CP) \
	    $(PKG_INSTALL_DIR)$(PYTHON_PKG_DIR)/* \
	    $(1)$(PYTHON_PKG_DIR)/

	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) \
	    $(PKG_INSTALL_DIR)/usr/bin/* \
	    $(1)/usr/bin/
endef

$(eval $(call BuildPackage,socksipychain))
