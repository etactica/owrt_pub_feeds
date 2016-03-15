#
# mqttcollect package for OpenWrt
# Karl Palsson <karlp@etactica.com> 2016
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mqttcollect
PKG_REV:=b2a95bb79187273068d288380bfbf30b52c13cf2
PKG_VERSION:=20160315-$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_SOURCE_URL:=https://github.com/jpmens/mqttcollect.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/default
SECTION:=net
CATEGORY:=Network
TITLE:=collectd 'Exec' plugin for mqtt
DEPENDS:= +libmosquitto
endef

define Package/$(PKG_NAME)
$(Package/$(PKG_NAME)/default)
endef

define Package/$(PKG_NAME)/description
mqttcollect is an executable program which is used with collectd(1). It
subscribes to any number of MQTT topics you specify, and prints values
to stdout for collectd to process in an exec plugin block.
endef

define Package/$(PKG_NAME)/conffiles
/etc/mqttcollect.ini
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/mqttcollect.ini.example $(1)/etc/mqttcollect.ini
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
