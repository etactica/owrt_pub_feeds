# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

include $(TOPDIR)/rules.mk

PKG_NAME:=python-pybgapi
PKG_VERSION:=1.2.0
PKG_RELEASE:=1

PYPI_NAME:=pybgapi
PKG_HASH:=0d72beec8b68e9fc844f7a26376e66dae9dfda981127fcb17ca91dc45df1dcb0

PKG_LICENSE:=zlib
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/python3-pybgapi
  SECTION:=lang-python
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=py interface to silabs BGAPI protocol
  URL:=https://pypi.org/project/pybgapi/
  DEPENDS:=+python3-light
endef

define Package/python3-pybgapi/description
pyBGAPI provides a Python interface for the BGAPI binary protocol.
It reads the BGAPI definition file and dynamically generates a parser for it.

This is the protocol used for Silicon labs bluetooth radios running in NCP mode.
You will also need the appropriate sl_bt.xapi file for the corresponding NCP firmware on your device.
endef

$(eval $(call Py3Package,python3-pybgapi))
$(eval $(call BuildPackage,python3-pybgapi))
$(eval $(call BuildPackage,python3-pybgapi-src))