#
# Copyright (C) 2007-2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=SQLAlchemy
PKG_VERSION:=0.7.9
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://pypi.python.org/packages/source/S/SQLAlchemy/
PKG_MD5SUM:=a0b58defc5ad0c7e1baeb932f62d08dd
PKG_BUILD_DEPENDS:=python

include $(INCLUDE_DIR)/package.mk
$(call include_mk, python-package.mk)

define Package/$(PKG_NAME)
 SUBMENU:=Python
 SECTION:=lang
 CATEGORY:=Languages
 TITLE:=pysqlalchemy
 URL:=http://pypi.python.org/packages/source/S/SQLAlchemy
 DEPENDS:=+python-mini
endef

define Package/$(PKG_NAME)/description
  SQLAlchemy
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
