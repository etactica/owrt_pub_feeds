#!/bin/sh
set -e
# Run this to regenerate your pot files...
APPS="luci-app-snmpd output-klappir output-senseone output-statsd"
APPS="${APPS} output-dexma output-db output-thingsboard"

for x in ${APPS}; do
	# you need i18-scan.pl from openwrt-19.07 or later.
	# the fix required is https://github.com/openwrt/luci/issues/2738
	~/src/luci/build/i18n-scan.pl ../$x > po/templates/$x.pot
	# Below if you have a busted i18n-scan
	#find ../$x -type f -name '*.lua' -exec xgettext -i {} -L lua -o po/templates/.$x.pot -j --omit-header --copyright-holder='' \;
	#cat po/templates/.$x.pot | msgcat -s - -o po/templates/$x.pot
	#rm -f po/templates/.$x.pot
done

# This then updates any .po translations with the new .pot files from above
~/src/luci/build/i18n-update.pl po

