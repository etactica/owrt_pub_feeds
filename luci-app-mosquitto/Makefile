# Copyright (c) 2012 OpenWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mosquitto
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    $(Package/mosquitto/defualt)
    SECTION:=luci
    CATEGORY:=LuCI
    SUBMENU:=3. Applications
    TITLE:=LuCI support for mosquitto configuration
    URL:=http://www.mosquitto.org
    DEPENDS:=+mosquitto
endef

define Package/$(PKG_NAME)/description
 Provides a webadmin for some basic mosquitto parameters. (Not even close to
all of them) Also provides a uci -> mosquitto config converter and init
script replacement to use the uci config.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/mosquitto
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
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/mosquitto $(1)/etc/config/mosquitto
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/mosquitto.uci-defaults $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/mosquitto.uci.convert $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
