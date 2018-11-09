# Copyright (c) 2014 OpenWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-snmpd
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_ARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    SECTION:=luci
    CATEGORY:=LuCI
    SUBMENU:=3. Applications
    TITLE:=LuCI support for net-snmp's snmpd configuration
    URL:=http://www.net-snmp.org
    DEPENDS:= +luci-base
    #DEPENDS:=+snmpd
    # or on snmpd-static?
endef

define Package/$(PKG_NAME)/description
 Provides a webadmin for some very basic snmpd parameters. (Not even close to
all of them)
endef

define Package/$(PKG_NAME)/conffiles
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
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
