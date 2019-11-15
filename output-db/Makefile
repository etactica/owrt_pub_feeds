# Copyright (c) 2019 karlp@etactica.com

include $(TOPDIR)/rules.mk

PKG_NAME:=output-db
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_ARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    SECTION:=remake
    CATEGORY:=Remake
    TITLE:=$(PKG_NAME) - message output daemon
    URL:=http://github.com/etactica/owrt_pub_feeds/output-db
    # TODO - maybe? DEPENDS:=+ca-certificates
endef

define Package/$(PKG_NAME)/description
Contains configs and UI for connecting an eTactica EG to a "generic"
SQL server.  Allows some tuning of the sql statements used for various operations.
Supports writing both cabinet metadata and aggregation data.

endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

# Below here is common, based on notes from jow_laptop
# We only copy luasrc/lualib specially, everything else just goes into files, which is already handled
define Build/Prepare
	for d in luasrc lualib; do \
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

LUA_LIBRARYDIR = /usr/lib/lua
LUCI_LIBRARYDIR = $(LUA_LIBRARYDIR)/luci

define Package/$(PKG_NAME)/install
	[ -d $(PKG_BUILD_DIR)/lualib ] && \
          $(INSTALL_DIR) $(1)$(LUA_LIBRARYDIR) && \
          $(CP) $(PKG_BUILD_DIR)/lualib/* $(1)$(LUA_LIBRARYDIR)/ \
          || true
	[ -d $(PKG_BUILD_DIR)/luasrc ] && \
          $(INSTALL_DIR) $(1)$(LUCI_LIBRARYDIR) && \
          $(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)$(LUCI_LIBRARYDIR)/ \
          || true
	# Application itself, and it's packaging
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
