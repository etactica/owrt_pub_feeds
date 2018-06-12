#
# Consider this file to be released into the Public Domain.
# If not possible, consider it available under your choice of the
# BSD 2 clause, MIT, X11 or ISC licenses

include $(TOPDIR)/rules.mk

PKG_NAME:=lua_cliargs

PKG_REV:=3.0-2
PKG_VERSION:=$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/amireh/lua_cliargs
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
  TITLE:=A command-line argument parsing module for Lua.
  URL:=$(PKG_SOURCE_URL)
  DEPENDS:=
endef

define Package/$(PKG_NAME)/description
cliargs is a command-line argument parser for Lua. It supports several types of arguments:

* required arguments
* optional arguments with different notations: -short-key VALUE and/or --expanded-key=VALUE
* optional arguments with multiple-values that get appended to a list
* optional "flag" arguments (on/off options) with notations: -short-key and/or --expanded-key
* a single optional "splat" argument which can be repeated (must be the last argument)

Optional arguments can have default values (strings), flags always default to 'true'.
endef

define Build/Compile
        echo "Nothing to compile, pure lua package"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/
	$(CP) $(PKG_BUILD_DIR)/src/* $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
