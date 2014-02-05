#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=MarkupSafe
PKG_VERSION:=0.18
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://pypi.python.org/packages/source/M/MarkupSafe
PKG_MD5SUM:=f8d252fd05371e51dec2fe9a36890687
PKG_BUILD_DEPENDS:=python

include $(INCLUDE_DIR)/package.mk
$(call include_mk, python-package.mk)

define Package/$(PKG_NAME)
 SUBMENU:=Python
 SECTION:=lang
 CATEGORY:=Languages
 TITLE:=MarkupSafe
 URL:=http://www.pocoo.org/projects/markupsafe/
 DEPENDS:=+python-mini
endef

define Package/$(PKG_NAME)/description
  MarkupSafe is a library for Python that implements a unicode string that is
aware of HTML escaping rules and can be used to implement automatic string
escaping. It is used by Jinja 2, the Mako templating engine, the Pylons web
framework and many more.
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
