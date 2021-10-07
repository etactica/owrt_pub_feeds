## output-statsd
As opposed to the StatsD support built into other applications, which tracks
the statistics of those applications themselves, output-statsd handles sending
the eTactica live stream data directly to a StatsD server.

You need a StatsD server somewhere to play with this.
* [Graphite+StatsD on Docker](https://github.com/graphite-project/docker-graphite-statsd)
* [Telegraf (InfluxDB) on Docker](https://hub.docker.com/_/telegraf/)

This service can only publishes hard metrics, there is no support at present
for using mixtures of tags and metrics.

### Example metrics
* cabinetname.branchname.current.phasenumber
* cabinetname.deviceid.temp
* cabinetname.branchname.cumulative_wh
* cabinetname.branchname.pf.phasenumber
* cabinetname.branchname.volt.phasenumber

## Features
* Can use the cabinet model to make more useable metric names

## Limitations
* Only a single instance is supported.  If you need to send to multiple
StatsD servers from the same gateway, please get in touch.
* All live variables are sent, there's no filtering or selecting.
