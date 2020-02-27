# Consider this packaging released into the public domain.
# If not available, consider it available under your choice of:
#   Apache2, ISC, MIT or BSD2claus licenses
# Karl Palsson <karlp@etactica.com>
include $(TOPDIR)/rules.mk

PKG_NAME:=aws-rds-certs
PKG_VERSION:=2020-01-23
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=Encryption
  TITLE:=aws-rds-certs
  URL:=https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html
  DEPENDS:=
endef

define Package/$(PKG_NAME)/description
  This contains the root certificates provided by Amazon Web Services
for securing connections to their RDS product.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
