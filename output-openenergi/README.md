## output-openenergi

Listens to the live data stream, finds all feasible power readings, and posts
them to the Open Energi MQTT broker whenever they have changed sufficiently,
or have become stale.

## Entity ID relationships
Open Energi Entity ID <-> local deviceid mappings are handled by the  UCI config
file /etc/config/output-openenergi

Simple three phase meters use their natural ID, while Power Bars use the normal ID/channel
form.

## Links for further information
https://github.com/openenergi/flex-device-sdk-java/blob/master/Messages.md#mes


