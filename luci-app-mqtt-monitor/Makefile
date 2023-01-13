include $(TOPDIR)/rules.mk
ifeq ($(REMAKE_TAG),)
PKG_REV:=HEAD
else
PKG_REV:=$(REMAKE_TAG)
endif

PKG_NAME:=mqtt-mon
PKG_VERSION:=2.0-$(PKG_REV)
PKG_RELEASE:=1

UCODE_LIBRARYDIR = /usr/share/ucode

include $(INCLUDE_DIR)/package.mk

# From luci.mk
define SubstituteVersion
	$(FIND) $(1) -type f -name '*.htm' | while read src; do \
		$(SED) 's/<%# *\([^ ]*\)PKG_VERSION *%>/\1$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))/g' \
		    -e 's/"\(<%= *\(media\|resource\) *%>[^"]*\.\(js\|css\)\)"/"\1?v=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))"/g' \
			"$$$$src"; \
	done; \
	$(FIND) $(1) -type f -name '*.ut' | while read src; do \
		$(SED) 's/{# *\([^ ]*\)PKG_VERSION *#}/\1$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))/g' \
		    -e 's/"\({{ *\(media\|resource\) *}}[^"]*\.\(js\|css\)\)"/"\1?v=$(if $(PKG_VERSION),$(PKG_VERSION),$(PKG_SRC_VERSION))"/g' \
			"$$$$src"; \
	done
endef


define Package/$(PKG_NAME)/default
  SECTION:=remake
  CATEGORY:=Remake
  TITLE:=Friendly mqtt-mon
  DEPENDS:= # FIXME you need to provide this yourself
endef

define Package/$(PKG_NAME)/default/description
 FIXME - you need to provide this yourself!
endef

define Package/$(PKG_NAME)
	$(call Package/$(PKG_NAME)/default)
endef

define Package/$(PKG_NAME)/description
	$(call Package/$(PKG_NAME)/default/description)
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/mqtt-mon
endef

define Package/$(PKG_NAME)/install
	[ -d ./ucode ] && \
          $(INSTALL_DIR) $(1)$(UCODE_LIBRARYDIR) && \
          cp -pR ./ucode/* $(1)$(UCODE_LIBRARYDIR)/ && \
          $(call SubstituteVersion,$(1)$(UCODE_LIBRARYDIR)/) \
          || true
	$(CP) ./files/* $(1)/
endef

define Build/Compile
	echo "lol, nothing to compile here"
endef

$(eval $(call BuildPackage,$(PKG_NAME)))