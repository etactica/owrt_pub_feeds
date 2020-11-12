# Copyright (c) 2020 karlp@etactica.com

include $(TOPDIR)/rules.mk

PKG_NAME:=io-charging-on
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    SECTION:=remake
    CATEGORY:=Remake
    TITLE:=$(PKG_NAME) - charger management
    URL:=http://github.com/etactica/owrt_pub_feeds/io-charging-on
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Listens to live data Mains data, polls a set of connected EV chargers,
and continually updates the chargers with available power.

Contains a UI for selecting chargers and assigning mains.

Algorithm and implementation for Orku náttúrunnar, on.is
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef


# Below here is common, based on notes from jow_laptop

define Build/Prepare
	for d in luasrc lualib htdocs root; do \
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
	# Install luci stuff...
	[ -d $(PKG_BUILD_DIR)/luasrc ] && \
          $(INSTALL_DIR) $(1)$(LUCI_LIBRARYDIR) && \
          $(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)$(LUCI_LIBRARYDIR)/ \
          || true
	[ -d $(PKG_BUILD_DIR)/lualib ] && \
          $(INSTALL_DIR) $(1)$(LUA_LIBRARYDIR) && \
          cp -pR $(PKG_BUILD_DIR)/lualib/* $(1)$(LUA_LIBRARYDIR)/ \
          || true
	# Application itself, and it's packaging
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
