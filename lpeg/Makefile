#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=lpeg
PKG_VERSION:=0.12
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/LuaDist/lpeg/archive/
PKG_BUILD_DEPENDS:=liblua

include $(INCLUDE_DIR)/package.mk
# lpeg includes a cmake file, but it's busted for openwrt's purposes.

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=lpeg (Parsing Expression Grammars)
  URL:=http://www.inf.puc-rio.br/~roberto/lpeg/
  DEPENDS:=+lua
endef

define Package/$(PKG_NAME)/description
LPeg is a new pattern-matching library for Lua, based on Parsing Expression
Grammars (PEGs).
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lpeg.so $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
