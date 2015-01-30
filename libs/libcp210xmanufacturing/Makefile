#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=libcp210xmanufacturing
PKG_REV:=HEAD
#PKG_REV:=1cbd63a1f0ba8cb7f694dc206b67b276b907c0c3

PKG_VERSION:=1-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/remakeelectric/cp210xmanufacturing.git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_MAINTAINER:=Karl Palsson <karlp@remake.is>

TARGET_CFLAGS+=$(FPIC)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=support lib for configuring cp210x devices
	DEPENDS:=+libusb-1.0 +libstdcpp
endef

define Package/$(PKG_NAME)/description
 A package providing SiLabs AN721 software library "CP210xManufacturing" in
as close to "as provided" form, only massaged enough to build for OpenWrt

You would still need your own application to use this library.

Note, this needs c++ and libusb!
endef

define Package/$(PKG_NAME)/config
config LIBCP210XMANUFACTURING_EXAMPLE
        bool "include example app"
        depends on PACKAGE_libcp210xmanufacturing
        default no
        help
	  Installs the original SiLabs demo application

config LIBCP210xMANUFACTURING_CONTRIB
	bool "include contributed tools"
	depends on PACKAGE_libcp210xmanufacturing
	default yes
	help
	  Install actually useful tools, instead of hacky demos from Silabs
	  (Hopefully actually useful....)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/CP210xManufacturing/*.h $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/Release/Linux/$(PKG_NAME).so* $(1)/usr/lib/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/Release/Linux/$(PKG_NAME).so* $(1)/usr/lib/
ifeq ($(CONFIG_LIBCP210XMANUFACTURING_EXAMPLE),y)
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/Release/Linux/cp210xmanufacturing-example $(1)/usr/bin/
endif
ifeq ($(CONFIG_LIBCP210xMANUFACTURING_CONTRIB),y)
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/contrib/bin/* $(1)/usr/bin/
endif
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
