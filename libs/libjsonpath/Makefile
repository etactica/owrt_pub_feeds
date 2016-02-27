#
# Karl Palsson <karlp@tweak.net.au> Feb 2016
#

include $(TOPDIR)/rules.mk

PKG_REV:=d3d28982088ca86c123688a2912316590d30dcb1
PKG_NAME:=libjsonpath
PKG_VERSION:=1.0-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_SOURCE_URL:=git@github.com:karlp/jsonpath.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_MAINTAINER:=Karl Palsson <karlp@tweak.net.au>
PKG_LICENSE:=oh dear

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
CMAKE_INSTALL:=1

define Package/$(PKG_NAME)/default
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=openwrt jsonfilter extracted to libary
  DEPENDS:=+libjson-c
endef

define Package/$(PKG_NAME)
    $(Package/$(PKG_NAME)/default)
endef

define Package/$(PKG_NAME)/description
  existing jsonfilter app: http://git.openwrt.org/?p=project/jsonpath.git;a=summary
 ripped out to a lib.  _desired_ to move upstream in some form or another
endef

define Package/InstallDev
        $(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
        $(CP) $(PKG_INSTALL_DIR)/usr/lib/* $(1)/usr/lib/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/libjsonpath.so $(1)/usr/lib
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
