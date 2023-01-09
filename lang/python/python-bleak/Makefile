# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

include $(TOPDIR)/rules.mk

PKG_NAME:=python-bleak
PKG_VERSION:=0.19.5
PKG_RELEASE:=1

PYPI_NAME:=bleak
PKG_HASH:=87845a96453c58c19031c735444a7b3156800534bcd3f23ba74e119e9ae3cd88

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/python3-bleak
  SECTION:=lang-python
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=bluetooth le asyncio klient
  URL:=https://github.com/hbldh/bleak
  DEPENDS:=+python3-light
endef

define Package/python3-bleak/description
Bleak is an acronym for Bluetooth Low Energy platform Agnostic Klient.

Bleak is a GATT client software, capable of connecting to BLE devices acting as GATT servers.
It is designed to provide a asynchronous, cross-platform Python API to
connect and communicate with e.g. sensors
endef

$(eval $(call Py3Package,python3-bleak))
$(eval $(call BuildPackage,python3-bleak))
$(eval $(call BuildPackage,python3-bleak-src))