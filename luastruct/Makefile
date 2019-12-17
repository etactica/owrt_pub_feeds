include $(TOPDIR)/rules.mk

PKG_NAME:=luastruct
PKG_VERSION:=0.3
PKG_RELEASE:=1

PKG_SOURCE:=struct-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://www.inf.puc-rio.br/~roberto/struct
PKG_HASH:=1669dda189f87cf8b180652411a9974d9327367f762c290962fa0d89530707f6
# Workaround original tarball not having a parent directory
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_UNPACK:=gzip -dc $(DL_DIR)/$(PKG_SOURCE) | $(TAR) -C $(PKG_BUILD_DIR) -xf -

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=LuaStruct
  URL:=http://www.inf.puc-rio.br/~roberto/struct/
  DEPENDS:=+lua
  MAINTAINER:=Karl Palsson <karlp@etactica.com>
endef

define Package/$(PKG_NAME)/description
  This library offers basic facilities to convert Lua values to and from
  C structs. Its main functions are struct.pack, which packs multiple Lua
  values into a struct-like string; and struct.unpack, which unpacks
  multiple Lua values from a given struct-like string.
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/ \
		LUADIR="$(STAGING_DIR)/usr/include/" \
		CC="$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -std=gnu99" \
		LD="$(TARGET_CROSS)ld -shared"
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/struct.so $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
