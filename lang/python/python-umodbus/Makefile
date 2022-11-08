# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

include $(TOPDIR)/rules.mk

PKG_NAME:=python-umodbus
PKG_VERSION:=1.0.4
PKG_RELEASE:=1

PYPI_NAME:=uModbus
PKG_HASH:=26bbbeff02d6d8a3e29bb0f9d9044c672d55fc1687afe4297a2f7d68175103a7

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/python3-umodbus
  SECTION:=lang-python
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=umodbus userspace bindings
  URL:=https://github.com/AdvancedClimateSystems/uModbus/
  DEPENDS:=+python3-light
endef

define Package/python3-umodbus/description
uModbus or (μModbus) is a pure Python implementation of the Modbus protocol
as described in the MODBUS Application Protocol Specification V1.1b3.
uModbus implements both a Modbus client (both TCP and RTU) and a Modbus server (both TCP and RTU)
endef

$(eval $(call Py3Package,python3-umodbus))
$(eval $(call BuildPackage,python3-umodbus))
$(eval $(call BuildPackage,python3-umodbus-src))