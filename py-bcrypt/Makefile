#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=py-bcrypt
PKG_VERSION:=0.4
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://py-bcrypt.googlecode.com/files/
PKG_MD5SUM:=dd8b367d6b716a2ea2e72392525f4e36
PKG_BUILD_DEPENDS:=python

include $(INCLUDE_DIR)/package.mk
$(call include_mk, python-package.mk)

define Package/$(PKG_NAME)
 SUBMENU:=Python
 SECTION:=lang
 CATEGORY:=Languages
 TITLE:=$(PKG_NAME)
 URL:=http://code.google.com/p/py-bcrypt/
 DEPENDS:=+python  # No idea if -mini is enough!
endef

define Package/$(PKG_NAME)/description
 py-bcrypt is a Python wrapper of OpenBSD's Blowfish password hashing code,
as described in "A Future-Adaptable Password Scheme" by Niels Provos
and David Mazières
endef

define Build/Compile
	$(call Build/Compile/PyMod,,install --prefix=/usr --root=$(PKG_INSTALL_DIR))
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)$(PYTHON_PKG_DIR)
	$(CP) \
                $(PKG_INSTALL_DIR)$(PYTHON_PKG_DIR)/* \
                $(1)$(PYTHON_PKG_DIR)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
