#!/bin/sh
APP=output-senseone

case "$ACTION" in
	stratum)
		logger -t $APP "Starting on NTP stratum event"
		/etc/init.d/$APP start
		;;
	unsync)
		logger -t $APP "NTP sync lost, timestamps will slowly drift!"
		# Don't turn _off_ anything here, otherwise you lose all chance of offline buffering!
		;;
esac
