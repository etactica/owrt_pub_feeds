#
# Consider this file to be released into the Public Domain.
# If not possible, consider it available under your choice of the
# BSD 2 clause, MIT, X11 or ISC licenses

include $(TOPDIR)/rules.mk

PKG_NAME:=mediator_lua

PKG_REV:=1.1.2-0
PKG_VERSION:=$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/Olivine-Labs/mediator_lua.git
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
  TITLE:=Mediator pattern implementation for pub-sub management
  URL:=http://olivinelabs.com/mediator_lua/
  DEPENDS:=
endef

define Package/$(PKG_NAME)/description
	mediator_lua is a simple class that allows you to listen to events
by subscribing to and sending data to channels. Its purpose is to help you
decouple code where you might otherwise have functions calling functions
calling functions, and instead simply call
   mediator.publish("chat", { message = "hi" })
endef

define Build/Compile
        echo "Nothing to compile, pure lua package"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/mediator.lua $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
