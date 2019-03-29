# Copyright (c) 2017 karlp@etactica.com

include $(TOPDIR)/rules.mk

PKG_NAME:=output-activitystream
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_ARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    SECTION:=remake
    CATEGORY:=Remake
    TITLE:=$(PKG_NAME) - message output daemon
    URL:=http://github.com/etactica/owrt_pub_feeds/output-activitystream
    DEPENDS:=+ca-certificates
endef

define Package/$(PKG_NAME)/description
Contains configs and UI for connecting an eTactica EG to Activity Stream.

 Provides a webadmin for basic account configuration parameters.
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
          $(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)$(LUCI_LIBRARYDIR)/
	[ -d $(PKG_BUILD_DIR)/luasrc ] && \
          $(INSTALL_DIR) $(1)$(LUCI_LIBRARYDIR) && \
          $(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)$(LUCI_LIBRARYDIR)/
	[ -d $(PKG_BUILD_DIR)/htdocs ] && \
          $(INSTALL_DIR) $(1)$(HTDOCS) && \
          $(CP) $(PKG_BUILD_DIR)/htdocs/* $(1)$(HTDOCS)/ \
          || true
	[ -d $(PKG_BUILD_DIR)/root ] && \
          $(INSTALL_DIR) $(1)/ && \
          $(CP) $(PKG_BUILD_DIR)/root/* $(1)/ \
          || true
	# Application itself, and it's packaging
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
