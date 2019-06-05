# _heavily_ based on luci.mk handling of languages, 
# but trimmed down as those already exist by the time our 
# translations land.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/version.mk

PKG_NAME:=etactica-open-translations
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_ARCH:=all

include $(INCLUDE_DIR)/package.mk

define Build/Compile
endef

LUCI_LIBRARYDIR = /usr/lib/lua/luci

# Automatically builds translations for any po files found.
ELANGS:=$(sort $(filter-out templates,$(notdir $(wildcard ${CURDIR}/po/*))))

define LuciTranslation
  define Package/$$(PKG_NAME)-$(1)
    SECTION:=luci
    CATEGORY:=LuCI
    SUBMENU:=3rd Party
    TITLE:=eTactica open translations for $(1)
    DEFAULT:=y
    PKGARCH:=all
  endef

  define Package/$$(PKG_NAME)-$(1)/description

    eTactica translations for "$(1)"
    These are the translations for files in the public feed.
  endef

  define Package/$$(PKG_NAME)-$(1)/install
	$$(INSTALL_DIR) $$(1)$(LUCI_LIBRARYDIR)/i18n
	$(foreach po,$(wildcard ${CURDIR}/po/$(1)/*.po), \
		po2lmo $(po) \
			$$(1)$(LUCI_LIBRARYDIR)/i18n/$(basename $(notdir $(po))).$(1).lmo;)
  endef

endef

$(foreach lang,$(ELANGS),$(eval $(call LuciTranslation,$(lang))))
$(foreach lang,$(ELANGS),$(eval $(call BuildPackage,$(PKG_NAME)-$(lang))))

