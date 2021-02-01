include $(TOPDIR)/rules.mk

PKG_NAME:=wslay
PKG_VERSION:=1.1.1
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://github.com/tatsuhiro-t/wslay/releases/download/release-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_HASH:=166cfa9e3971f868470057ed924ae1b53f428db061b361b9a17c0508719d2cb5

PKG_LICENSE:=MIT
PKG_LICENSE_FIELS:=COPYING
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

PKG_BUILD_PARALLEL:=1
PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/wslay
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=The WebSocket library in C
  URL:=https://tatsuhiro-t.github.io/wslay/
endef

define Package/wslay/description
 Wslay is a WebSocket library written in C. It implements the protocol
version 13 described in RFC 6455. 

Wslay does not perform any I/O operations for its own. Instead, it offers
callbacks for them. This makes Wslay independent on any I/O frameworks,
SSL, sockets, etc. This makes Wslay portable across various platforms
and the application authors can choose freely I/O frameworks.
endef

TARGET_CFLAGS += $(FPIC)

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/wslay
	$(CP) $(PKG_INSTALL_DIR)/usr/include/wslay/* $(1)/usr/include/wslay
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libwslay.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libwslay.pc $(1)/usr/lib/pkgconfig/
endef

define Package/wslay/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libwslay.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,wslay))
