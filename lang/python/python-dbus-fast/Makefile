# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

include $(TOPDIR)/rules.mk

PKG_NAME:=python-dbus-fast
PKG_VERSION:=1.72.0
PKG_RELEASE:=1

PYPI_NAME:=dbus-fast
PYPI_SOURCE_NAME=dbus_fast
PKG_HASH:=9c5f09eba0da120abc60ad3ae2132ade4ad62f21bfbc26b1199a5a12c9ff4e3b

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/python3-dbus-fast
  SECTION:=lang-python
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=A faster version of dbus-next
  URL:=https://github.com/bluetooth-devices/dbus-fast
  DEPENDS:=+python3-light
endef

define Package/python3-dbus-fast/description
dbus-fast is a Python library for DBus that aims to be a performant
fully featured high level library primarily geared towards integration
of applications into Linux desktop and mobile environments.
endef

$(eval $(call Py3Package,python3-dbus-fast))
$(eval $(call BuildPackage,python3-dbus-fast))
$(eval $(call BuildPackage,python3-dbus-fast-src))