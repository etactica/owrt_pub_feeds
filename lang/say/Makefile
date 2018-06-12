#
# Consider this file to be released into the Public Domain.
# If not possible, consider it available under your choice of the
# BSD 2 clause, MIT, X11 or ISC licenses

include $(TOPDIR)/rules.mk

PKG_NAME:=say

PKG_REV:=1.3-1
PKG_VERSION:=$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/Olivine-Labs/say
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
  TITLE:=Lua string hashing library, useful for internationalization
  URL:=$(PKG_SOURCE_URL)
  DEPENDS:=
endef

define Package/$(PKG_NAME)/description
say is a simple string key/value store for i18n or ay other case
where you want namespaced strings.

Check out busted for extended examples.
endef

define Build/Compile
        echo "Nothing to compile, pure lua package"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/
	$(CP) $(PKG_BUILD_DIR)/src $(1)/usr/lib/lua/say
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
