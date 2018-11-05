#!/bin/sh
APP=output-senseone

case "$ACTION" in
	stratum)
		logger -t $APP "Starting on NTP stratum event"
		/etc/init.d/$APP start
		;;
	unsync)
		logger -t $APP "Stopping on NTP unsync event"
		/etc/init.d/$APP stop
		;;
esac
