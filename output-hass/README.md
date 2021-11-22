## Home Assistant Integration

This sends data from the 1/5/15/60 minute interval aggregate data stream to Home Assistant, via HA's
built in MQTT Integration.  You must have configured that first!

This side will handle automatically publishing datapoint metadata, so any as long
as the cabinet model is filled in, datapoints will all just magically appear in your home
assistant instance.  

## Internal notes for "how it works"

Fundamentally, we're simply bridging the selected [interval data topics](http://FIXME) to your configured
Home Assistant MQTT broker.  (Home Assistant->Configuration->Integrations->MQTT and then whatever broker you have configured there)
However, to make the points automatically discoverable, we're also handling the ["MQTT Discovery"](https://www.home-assistant.io/docs/mqtt/discovery/) as
per Home Assistant's directions.  To do this, we have a simple service that listens to the [cabinet metadata topics](http://FIXME)
and publishes the required formatted mqtt discovery messages as well.  There's no calculating or reformatting json in this,
so this should be a very lightweight process.

## (incomplete) TODO

* Better linking of our mdns/zeroconf discovery and the mqtt discovery
* data type selection better.  (global issue)
* see if there are better options for how the config discovery topics should be bundled...
* branding https://developers.home-assistant.io/blog/2020/05/08/logos-custom-integrations/
