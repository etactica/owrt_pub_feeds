# Copyright (c) 2012 OpenWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-pagekitec
PKG_VERSION:=1.3
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    $(Package/pagekite/defualt)
    SECTION:=luci
    CATEGORY:=LuCI
    SUBMENU:=3. Applications
    TITLE:=LuCI support for pagekite configuration
    URL:=http://www.pagekite.net
    PKGARCH:=all
    DEPENDS:=+luci-base +pagekitec
endef

define Package/$(PKG_NAME)/description
 Provides a webadmin for some basic pagekite parameters. (Not even close to
all of them) This package targets pagekitec, the C implementation of pagekite,
most suited for the OpenWrt environment.
endef


# Below here is common, based on notes from jow_laptop

define Build/Prepare
	for d in luasrc htdocs root; do \
          if [ -d ./$$$$d ]; then \
            mkdir -p $(PKG_BUILD_DIR)/$$$$d; \
                $(CP) ./$$$$d/* $(PKG_BUILD_DIR)/$$$$d/; \
          fi; \
	done
endef

define Build/Configure
endef

define Build/Compile
endef

HTDOCS = /www
LUA_LIBRARYDIR = /usr/lib/lua
LUCI_LIBRARYDIR = $(LUA_LIBRARYDIR)/luci

define Package/$(PKG_NAME)/install
	[ -d $(PKG_BUILD_DIR)/luasrc ] && \
          $(INSTALL_DIR) $(1)$(LUCI_LIBRARYDIR) && \
          cp -pR $(PKG_BUILD_DIR)/luasrc/* $(1)$(LUCI_LIBRARYDIR)/
	[ -d $(PKG_BUILD_DIR)/htdocs ] && \
          $(INSTALL_DIR) $(1)$(HTDOCS) && \
          cp -pR $(PKG_BUILD_DIR)/htdocs/* $(1)$(HTDOCS)/ \
          || true
	[ -d $(PKG_BUILD_DIR)/root ] && \
          $(INSTALL_DIR) $(1)/ && \
          cp -pR $(PKG_BUILD_DIR)/root/* $(1)/ \
          || true
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
