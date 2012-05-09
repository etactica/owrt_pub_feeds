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

PKG_NAME:=pagekite
PKG_VERSION:=0.4.6a
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://pagekite.net/pk/src/$(PKG_SOURCE)
PKG_MD5SUM:=28c28a0c9225dae0ce4e553868168e86

# See if this can mean we don't need distribute on the target!
#PKG_BUILD_DEPENDS:=python distribute/host
PKG_BUILD_DEPENDS:=python


#include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk
$(call include_mk, python-package.mk)

define Package/pagekite
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Make localhost servers publicly visible.
  URL:=http://pagekite.net
  DEPENDS+=+python-openssl +socksipychain +distribute
endef

define Package/pagekite/description
PageKite is a system for running publicly visible servers (generally
 web servers) on machines without a direct connection to the Internet,
 such as mobile devices or computers behind restrictive firewalls.
 PageKite works around NAT, firewalls and IP-address limitations by
 using a combination of  tunnels and reverse proxies.
 .
 Natively supported protocols: HTTP, HTTPS
 Partially supported protocols: IRC, Finger
 .
 Any other TCP-based service, including SSH and VNC, may be exposed
 as well to clients supporting HTTP Proxies.
endef

define Package/pagekite/conffiles
/etc/pagekite.d/pagekite.rc
endef

define Build/Configure
	$(call Build/Configure/Default,)
	# the very skanky alternative to a "patches" subdir, because I find quilt awkward
	$(SED) 's!from pagekite import APPVER!APPVER="$(PKG_VERSION)" #patched ;) !' $(PKG_BUILD_DIR)/setup.py
	$(SED) 's#prefix = /usr#; no overriding prefix! bad setup!#' $(PKG_BUILD_DIR)/setup.cfg
	$(SED) 's#install_lib =#; no overriding install_lib! bad setup!#' $(PKG_BUILD_DIR)/setup.cfg
endef

define Build/Compile
	$(call Build/Compile/PyMod,.,install --prefix=/usr --root=$(PKG_INSTALL_DIR),)
	# Make sure generated scripts try to use the right python...
	$(SED) 's,#!$(HOST_PYTHON_BIN),#!/usr/bin/$(PYTHON),' $(PKG_INSTALL_DIR)/usr/bin/*
endef

define Package/pagekite/install
	$(INSTALL_DIR) $(1)$(PYTHON_PKG_DIR)
	$(CP) \
	    $(PKG_INSTALL_DIR)$(PYTHON_PKG_DIR)/* \
	    $(1)$(PYTHON_PKG_DIR)/

	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) \
	    $(PKG_INSTALL_DIR)/usr/bin/* \
	    $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/pagekite.init $(1)/etc/init.d/pagekite
	$(INSTALL_DIR) $(1)/etc/pagekite.d
	$(INSTALL_CONF) ./files/pagekite.rc $(1)/etc/pagekite.d/pagekite.rc
endef

$(eval $(call BuildPackage,pagekite))
