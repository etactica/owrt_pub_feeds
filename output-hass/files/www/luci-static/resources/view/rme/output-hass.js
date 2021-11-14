'use strict';
'require form';
'require fs';
'require tools.widgets as widgets';

var TrimmedValue = form.Value.extend({
	write: function(sid, formvalue) {
		this.super("write", [sid, formvalue.trim()]);
	}
})

// FIXME - links to required peices
var desc = _(""
	+ "This service allows bridging eTactica interval aggregate stream data to Home Assistant"
	+ "<em>FIXME</em> add links to all required pieces"
	+ "You can select only which types of data to send right now, TODO: use shared granular data point selector widgets...."
	+ "This relies on Home Assistant's MQTT integration!"
	+ "The full set of MQTT configuration options aren't available here, you _may_ choose to disable the bridge, and manage it manually on the mosquitto page! (fix that text, it's gross)"
   	+ 'If the <a href=' + L.url("home/wizard/cabinet_model") + '>cabinet model</a> is not available, or has been disabled, the data points will use their hardware ids'
);

return L.view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('output-hass', _('Output HomeAssistant'), _('Output-HomeAssistant offers a basic method of writing basic interval data to a given Home Assistant instance'));

		s = m.section(form.TypedSection, 'instance', _('Instances'),
			_("You can run multiple instances of this service.  Choose a name and click 'Add' to make a new instance")
		);
		s.addremove = true;

		s.tab("general", _("General Settings"));
		s.tab("mqtt", _("MQTT Settings"), _("This is the connection details for the Home Assistant MQTT broker."));
		s.tab("statsd", _("StatsD"), _("Metrics on operation can be sent to a listening StatsD server, such as graphite"))

        o = s.taboption("general", form.Flag, "enabled", _("Enable this instance"), _("The service will not start until this is checked"));
        o.rmempty = false;


		o = s.taboption("general", form.ListValue, "interval", _("Interval to monitor and forward"), _("Default is 15 minute, but you can select finer/coarser grained"));
		o.optional = true;
		o.value("1min", "1 Minute");
		o.value("5min", "5 Minute");
		o.value("15min", "15 Minute");
		o.value("60min", "60 Minute");
		o.placeholder = "Default (1 Minute)";

        // FIXME - we're still hating this, we really need better selection of aggregates and totals and so on...
		o = s.taboption("general", form.MultiValue, "store_types", _("Data types to store"), _("Home Assistant doesn't charge for unused points, but it can make a mess and take up more storage, so better to only pick what you want"));
		o.multiple = true;
		o.optional = true;
		o.placeholder = _("Default (Active Energy)");
//		o.value("_all", _("All types seen"))
		o.value("energy", _("Active Energy"));
//		o.value("reactive_energy", _("Reactive Energy"));
		o.value("voltage", _("Voltage (interval mean)"));
		o.value("current", _("Current (interval mean)"));
		o.value("pf", _("Power Factor (interval mean)"));
		o.value("temperature", _("Temperature (interval mean)"));
//		o.value("pulse_count", _("Pulse count"));
		o.value("power", _("Power (interval mean)"));


		o = s.taboption("mqtt", TrimmedValue, "mqtt_host", _("MQTT Host"), _("Host of the HomeAssistant MQTT broker"));
		o.datatype = "host";

		o = s.taboption("mqtt", TrimmedValue, "mqtt_port", _("MQTT Port"));
		o.placeholder = "1883";
		o.datatype = "port";

		o = s.taboption("mqtt", TrimmedValue, "mqtt_discovery_prefix", _("Discovery Prefix"), _("What is the prefix used for MQTT discovery on your broker.  (You probably don't have to change this)"))
		o.placeholder = "homeassistant";
		o = s.taboption("mqtt", TrimmedValue, "mqtt_data_prefix", _("Data Prefix"), _("What topic tree to bridge our data to.  This affects the <em>data</em> only, and is only interesting if you have multiple overlapping data sources"))
		o.placeholder = "etactica/data";

		o = s.taboption("mqtt", TrimmedValue, "mqtt_user", _("MQTT username"), _("The username to use when connecting to the remote MQTT broker, may be blank"));
		o.placeholder = "some-user-name";

		o = s.taboption("mqtt", TrimmedValue, "mqtt_pass", _("MQTT password"), _("The password to use when connecting to the remote MQTT broker, may be blank"));
		o.placeholder = "some-password";
		o.password = true;

		o = s.taboption("mqtt", form.Flag, "mqtt_use_tls", _("Use TLS"), _("Use SSL/TLS for the broker connection"));
		o = s.taboption("mqtt", TrimmedValue, "mqtt_cafile", _("CA file"), _("If TLS is enabled, use this to verify the broker cert if provided.  Otherwise, use system CA bundle"));

		// TODO - have we covered enough mqtt bridge connection options here?  do we need tls-psk options as well?
		// Things that people may nerd out and want to use:
		// bridge_alpn, bridge_identity+bridge_psk, bridge_certfile+bridge_keyfile, bridge_require_ocsp
		// and then of course allll the other mqtt bridge options like round robin and try private and keepalive and blah blah blah, just don't let them use most of it!


		o = s.taboption("statsd", TrimmedValue, "statsd_namespace", _("Namespace for StatsD reporting"))
		o.placeholder = "apps.output-hass.<instanceid>"
		o.optional = true

		o = s.taboption("statsd", form.Value, "statsd_host", _("Hostname to send stats"))
		o.placeholder = "localhost"
		o.datatype = "host"
		o.optional = true

		o = s.taboption("statsd", form.Value, "statsd_port", _("UDP port to send stats"))
		o.placeholder = 8125
		o.datatype = "port"
		o.optional = true

		return m.render();
	}
});