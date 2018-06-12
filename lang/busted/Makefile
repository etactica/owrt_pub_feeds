#
# Consider this file to be released into the Public Domain.
# If not possible, consider it available under your choice of the
# BSD 2 clause, MIT, X11 or ISC licenses

include $(TOPDIR)/rules.mk

PKG_NAME:=busted

PKG_REV:=2.0.rc12-1
PKG_VERSION:=$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/Olivine-Labs/busted
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=v$(PKG_REV)

PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>
PKG_LICENSE:=MIT

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Elegant Lua unit testing
  URL:=http://olivinelabs.com/busted
  DEPENDS:=+luassert +lua_cliargs +luafilesystem +luaposix +lua-penlight +mediator_lua +say 
endef

define Package/$(PKG_NAME)/description
busted is a unit testing framework with a focus on being easy to use.
Supports Lua >= 5.1, luajit >= 2.0.0, and moonscript.

Busted requires dkjson if you want json output formatters.
endef

define Build/Compile
        echo "Nothing to compile, pure lua package"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/
	$(CP) $(PKG_BUILD_DIR)/busted $(1)/usr/lib/lua/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/busted $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
