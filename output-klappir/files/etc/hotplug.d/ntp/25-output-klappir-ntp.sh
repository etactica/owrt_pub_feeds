#!/bin/sh
. /lib/functions/procd.sh

echo "karl -got action <$ACTION>" >> /tmp/hotplug.ntp.logger

[ "$ACTION" = stratum ] || exit 0

/etc/init.d/output-klappir enabled && {
	logger -t output-klappir "starting on NTP stratum event"
	/etc/init.d/output-klappir start
}
