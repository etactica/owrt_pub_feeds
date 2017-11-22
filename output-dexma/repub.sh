#!/bin/sh
mosquitto_pub -t status/local/json/cabinet/CAFEBABE0002 -r -f sample-cabinet-bar1.json
mosquitto_pub -t status/local/json/cabinet/CAFEBABE0020 -r -f sample-cabinet-mains1.json
mosquitto_pub -t status/local/json/cabinet/CAFEBABE002A -r -f sample-cabinet-mains-3ph.json
