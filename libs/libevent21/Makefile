#
# Copyright (C) 2011-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libevent21
PKG_VERSION:=2.1.4
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/libevent-$(PKG_VERSION)-stable
PKG_SOURCE:=libevent-$(PKG_VERSION)-alpha.tar.gz
PKG_SOURCE_URL:=http://www.monkey.org/~provos/ \
	@SF/levent
PKG_MD5SUM:=b2405cc9ebf264aa47ff615d9de527a2
PKG_MAINTAINER:=Jo-Philipp Wich <jow@openwrt.org>

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/libevent21/Default
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Event notification
  URL:=http://www.monkey.org/~provos/libevent/
endef

define Package/libevent21/Default/description
	The libevent API provides a mechanism to execute a callback function
	when a specific event occurs on a file descriptor or after a timeout
	has been reached. Furthermore, libevent also support callbacks due
	to signals or regular timeouts.

	libevent is meant to replace the event loop found in event driven
	network servers. An application just needs to call event_dispatch()
	and then add or remove events dynamically without having to change
	the event loop.
endef

define Package/libevent21
  $(call Package/libevent21/Default)
  TITLE+= library (version 2.1 alpha)
endef

define Package/libevent21/description
	$(call Package/libevent21/Default/description)

	This package contains the libevent shared library historically
	containing both the core & extra libraries.
endef

define Package/libevent21-core
  $(call Package/libevent21/Default)
  TITLE+= core library (version 2.1)
endef

define Package/libevent21-core/description
	$(call Package/libevent21/Default/description)

	This package contains the libevent core shared library for the event,
	buffer & utility functions.
endef

define Package/libevent21-extra
  $(call Package/libevent21/Default)
  TITLE+= extra library (version 2.1)
endef

define Package/libevent21-extra/description
	$(call Package/libevent21/Default/description)

	This package contains the libevent extra shared library for specific
	protocols including HTTP, DNS & RPC.
endef

define Package/libevent21-openssl
  $(call Package/libevent21/Default)
  TITLE+= OpenSSL library (version 2.1)
  DEPENDS+=+libopenssl
endef

define Package/libevent21-openssl/description
	$(call Package/libevent21/Default/description)

	This package contains the libevent OpenSSL shared library for encrypted
	bufferevents.
endef

define Package/libevent21-pthreads
  $(call Package/libevent21/Default)
  TITLE+= Pthreads library (version 2.1)
  DEPENDS+=+libpthread
endef

define Package/libevent21-pthreads/description
	$(call Package/libevent21/Default/description)

	This package contains the libevent Pthreads shared library for
	threading & locking.
endef

TARGET_CFLAGS += $(FPIC)

CONFIGURE_ARGS += \
	--enable-shared \
	--enable-static \
	--disable-debug-mode

MAKE_FLAGS += \
	CFLAGS="$(TARGET_CFLAGS)"

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libevent*.{la,a,so} $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libevent*-2.1.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libevent*.pc $(1)/usr/lib/pkgconfig/
endef

define Package/libevent21/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libevent-2.1.so.* $(1)/usr/lib/
endef

define Package/libevent21-core/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libevent_core-2.1.so.* $(1)/usr/lib/
endef

define Package/libevent21-extra/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libevent_extra-2.1.so.* $(1)/usr/lib/
endef

define Package/libevent21-openssl/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libevent_openssl-2.1.so.* $(1)/usr/lib/
endef

define Package/libevent21-pthreads/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libevent_pthreads-2.1.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libevent21))
$(eval $(call BuildPackage,libevent21-core))
$(eval $(call BuildPackage,libevent21-extra))
$(eval $(call BuildPackage,libevent21-openssl))
$(eval $(call BuildPackage,libevent21-pthreads))
