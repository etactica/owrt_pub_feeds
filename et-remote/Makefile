include $(TOPDIR)/rules.mk

PKG_NAME:=et-remote
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
    SECTION:=remake
    CATEGORY:=Remake
    TITLE:=Remote Access support
    URL:=https://github.com/etactica/owrt_pub_feeds/tree/master/et-remote
    PKGARCH:=all
    DEPENDS:=+luci-base +pagekitec
endef

define Package/$(PKG_NAME)/description
 Provides a tailored UI for the eTactica remote access solution
endef

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
