#
# Consider this file to be released into the Public Domain.
# If not possible, consider it available under your choice of the
# BSD 2 clause, MIT, X11 or ISC licenses

include $(TOPDIR)/rules.mk

PKG_NAME:=remake-uglylog
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Karl Palsson <karlp@etactica.com>
PKG_LICENSE:=MIT/X11

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Lua syslog/console logging library
  DEPENDS:=+lua
endef

define Package/$(PKG_NAME)/description
"ugly" logging utility library.  Automatically logs to syslog if running as
a daemon under init, or stderr console if running as a regular application.
Requires lua posix library for syslog, falls back to console if not found.
endef

define Build/Compile
        echo "Nothing to compile, pure lua package"
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(CP) ./lualib/* $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
