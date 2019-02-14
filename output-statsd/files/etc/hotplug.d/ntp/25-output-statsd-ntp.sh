#!/bin/sh
. /lib/functions/procd.sh

[ "$ACTION" = stratum ] || exit 0

/etc/init.d/output-statsd enabled && {
	logger -t output-statsd "starting on NTP stratum event"
	/etc/init.d/output-statsd start
}
