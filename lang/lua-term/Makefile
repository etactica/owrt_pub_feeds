#
# Consider this file to be released into the Public Domain.
# If not possible, consider it available under your choice of the
# BSD 2 clause, MIT, X11 or ISC licenses

include $(TOPDIR)/rules.mk

PKG_NAME:=lua-term

PKG_REV:=0.07
PKG_VERSION:=$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/hoelzro/lua-term
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)

PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>
PKG_LICENSE:=MIT

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Lua module for manipulating a terminal
  URL:=$(PKG_SOURCE_URL)
  DEPENDS:=+liblua
endef

define Package/$(PKG_NAME)/description
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/term
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/term/*.lua $(1)/usr/lib/lua/term
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/core.so* $(1)/usr/lib/lua/term
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
