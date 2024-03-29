#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=openocd-next
PKG_SOURCE_VERSION:=c3993d318
PKG_VERSION:=v2021-09-$(PKG_SOURCE_VERSION)
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=git://git.code.sf.net/p/openocd/code
#PKG_MIRROR_HASH:=6f8c0ecf240427654ad5e911b44f78996da931209280f4a19c1215802ff14638

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING

PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>
PKG_CPE_ID:=cpe:/a:openocd:open_on-chip_debugger

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1
PKG_FIXUP:=autoreconf

PKG_CONFIG_DEPENDS:=CONFIG_PACKAGE_openocd-next_with_usb

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/nls.mk

define Package/openocd-next
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=OpenOCD Utility (next)
  URL:=http://openocd.sf.net/
  DEPENDS:=+PACKAGE_openocd-next_with_usb:libusb-1.0 \
	+PACKAGE_openocd-next_with_usb:libusb-compat \
	+PACKAGE_openocd-next_with_usb:libftdi1 \
	+PACKAGE_openocd-next_with_usb:hidapi
endef

define Package/openocd-next/config
  if PACKAGE_openocd-next
	config PACKAGE_openocd-next_with_usb
		bool "Build with support for USB adapters."
		default y
  endif
endef

define Package/openocd-next/description
OpenOCD provides on-chip programming and debugging support with a
layered architecture of JTAG interface and TAP support including:

- (X)SVF playback to facilitate automated boundary scan and FPGA/CPLD
  programming;
- debug target support (e.g. ARM, MIPS): single-stepping,
  breakpoints/watchpoints, gprof profiling, etc;
- flash chip drivers (e.g. CFI, NAND, internal flash);
- embedded TCL interpreter for easy scripting.

Several network interfaces are available for interacting with OpenOCD:
telnet, TCL, and GDB. The GDB server enables OpenOCD to function as a
"remote target" for source-level debugging of embedded systems using
the GNU GDB program (and the others who talk GDB protocol, e.g. IDA
Pro).

This contains a "next" version, ie, a little newer than packaged upstream
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	-$(RM) $(PKG_BUILD_DIR)/guess-rev.sh
endef

CONFIGURE_ARGS += \
	--prefix="/usr" \
	--disable-werror \
	MAKEINFO=true \
	$(if $(CONFIG_PACKAGE_openocd-next_with_usb),,PKG_CONFIG=false) \
	--enable-dummy \
	--enable-sysfsgpio

TARGET_CFLAGS += -DRELSTR=\\\"-$(PKG_VERSION)-$(PKG_RELEASE)-OpenWrt\\\"

define Build/Compile
        +$(MAKE_VARS) \
        $(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR)/$(MAKE_PATH)
endef

define Package/openocd-next/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/share/openocd
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/openocd $(1)/usr/bin/
	$(CP) $(PKG_INSTALL_DIR)/usr/share/openocd/scripts $(1)/usr/share/openocd
endef

$(eval $(call BuildPackage,openocd-next))
