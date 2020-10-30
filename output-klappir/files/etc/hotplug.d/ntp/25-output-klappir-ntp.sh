#!/bin/sh
. /lib/functions/procd.sh

[ "$ACTION" = stratum ] || exit 0

# Ignore if not enabled
[ $(uci get output-klappir.@general[0].enabled) -eq 0 ] && exit 0
/etc/init.d/output-klappir enabled || exit 0

logger -t output-klappir "starting on NTP stratum event"
/etc/init.d/output-klappir start "NTP Stratum event"
