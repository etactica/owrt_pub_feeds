include $(TOPDIR)/rules.mk

PKG_NAME:=lua-libmodbus
PKG_VERSION:=0.7
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://codeload.github.com/etactica/lua-libmodbus/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=70369f4c4e36421095bf00dcee36c633b4284eaa79bcfdfd230bfefb27acefda
PKG_SOURCE_VERSION:=v$(PKG_VERSION)

PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>
PKG_LICENSE:=MIT

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=$(PKG_NAME)
  URL:=https://github.com/etactica/lua-libmodbus
  DEPENDS:=+liblua +libmodbus
endef

define Package/$(PKG_NAME)/description
	lua-libmodbus is a binding to libmodbus,
	see also http://www.libmodbus.org
endef

define Build/Configure
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libmodbus.so $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
