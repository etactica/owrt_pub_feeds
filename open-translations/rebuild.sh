#!/bin/sh
set -e
# Run this to regenerate your pot files...
# FIXME really need to get luci-app-mosquitto upstreamed!
APPS="luci-app-mosquitto luci-app-snmpd output-klappir output-senseone output-statsd"

for x in ${APPS}; do
	# Must use the "real" version from the master branch, with bugfixes in it.
	~/src/luci/build/i18n-scan-real.pl ../$x > po/templates/$x.pot
	# Below if you have a busted i18n-scan
	#find ../$x -type f -name '*.lua' -exec xgettext -i {} -L lua -o po/templates/.$x.pot -j --omit-header --copyright-holder='' \;
	#cat po/templates/.$x.pot | msgcat -s - -o po/templates/$x.pot
	#rm -f po/templates/.$x.pot
done

# This then updates any .po translations with the new .pot files from above
~/src/luci/build/i18n-update.pl po

