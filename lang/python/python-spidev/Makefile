# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

include $(TOPDIR)/rules.mk

PKG_NAME:=python-spidev
PKG_VERSION:=3.5
PKG_RELEASE:=1

PYPI_NAME:=spidev
PKG_HASH:=8a7f5c289f161ea2ac4697fa8a10918232c990678dd0053084b3c43b1363910d

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/python3-spidev
  SECTION:=lang-python
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=spidev userspace bindings
  URL:=https://github.com/doceme/py-spidev
  DEPENDS:=+python3-light
endef

define Package/python3-spidev/description
This project contains a python module for interfacing with SPI devices from user space via the spidev linux kernel driver.
endef

$(eval $(call Py3Package,python3-spidev))
$(eval $(call BuildPackage,python3-spidev))
$(eval $(call BuildPackage,python3-spidev-src))