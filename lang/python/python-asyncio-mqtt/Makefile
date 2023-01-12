# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

include $(TOPDIR)/rules.mk

PKG_NAME:=python-asyncio-mqtt
PKG_VERSION:=0.16.1
PKG_RELEASE:=1

PYPI_NAME:=asyncio-mqtt
PYPI_SOURCE_NAME:=asyncio_mqtt
PKG_HASH:=38416481bb7cc9613c6a1a8e58b8f9f9c9a522d93411003e8000e74ef2b7ed85

PKG_LICENSE:=BSD-3-Clause
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/python3-asyncio-mqtt
  SECTION:=lang-python
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=Idiomatic asyncio wrapper around paho-mqtt
  URL:=https://pypi.org/project/asyncio-mqtt/
  DEPENDS:=+python3-light +python3-paho-mqtt
endef

define Package/python3-asyncio-mqtt/description
asyncio-mqtt combines the stability of the time-proven paho-mqtt library with a modern, asyncio-based interface.

    No more callbacks! 👍
    No more return codes (welcome to the MqttError)
    Graceful disconnection (forget about on_unsubscribe, on_disconnect, etc.)
    Compatible with async code
    Fully type-hinted
    Did we mention no more callbacks?
endef

$(eval $(call Py3Package,python3-asyncio-mqtt))
$(eval $(call BuildPackage,python3-asyncio-mqtt))
$(eval $(call BuildPackage,python3-asyncio-mqtt-src))