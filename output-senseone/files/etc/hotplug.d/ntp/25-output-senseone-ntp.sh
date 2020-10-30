#!/bin/sh
APP=output-senseone

case "$ACTION" in
	stratum)
		# Ignore if not enabled
		[ $(uci get $APP.@general[0].enabled) -eq 0 ] && exit 0
		/etc/init.d/$APP enabled || exit 0

		logger -t $APP "Starting on NTP stratum event"
		/etc/init.d/$APP start
		;;
	unsync)
		logger -t $APP "NTP sync lost, timestamps will slowly drift!"
		# Don't turn _off_ anything here, otherwise you lose all chance of offline buffering!
		;;
esac
