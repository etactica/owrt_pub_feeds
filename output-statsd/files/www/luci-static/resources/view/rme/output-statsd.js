'use strict';
'require form';
'require fs';
'require ui';
'require tools.widgets as widgets';

var desc = _(""
	+ "This service handles bridging eTactica live stream data, and posting "
    + "<em>all</em> live variables to a StatsD server."
	+ "<h4>Before you start</h4>"
	+ "You need a StatsD server somewhere.  Examples: "
   	+ "<ul>"
   	+ '<li><a href="https://github.com/graphite-project/docker-graphite-statsd">Graphite+StatsD on Docker</a>'
  	+ '<li><a href="https://hub.docker.com/_/telegraf/">Telegraf (InfluxDB) on Docker</a>'
   	+ "</ul>"
   	+ '<h4>Notes</h4>'
   	+ 'This service can only publishes hard metrics, there is no support at present for using mixtures of tags and metrics.'
   	+ '<ul>Example metrics (gauges)'
   	+ '<li>cabinetname.branchname.current.phasenumber'
   	+ '<li>cabinetname.deviceid.temp'
   	+ '<li>cabinetname.branchname.cumulative_wh'
   	+ '<li>cabinetname.branchname.pf.phasenumber'
   	+ '<li>cabinetname.branchname.volt.phasenumber'
   	+ '</ul>'
   	+ 'If the <a href=' + L.url("home/wizard/cabinet_model") + '>cabinet model</a> is not available, or has been disabled, the meter device hardware ids are used instead.'
);

var TrimmedValue = form.Value.extend({
	write: function(sid, formvalue) {
		this.super("write", [sid, formvalue.trim()]);
	}
})

return L.view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('output-statsd', _('Output StatsD'), desc);

		s = m.section(form.TypedSection, 'general',	_("Configuration"));
		s.anonymous = true;

		s.tab("general", _("General Settings"));

        o = s.taboption("general", form.Flag, "enabled", _("Enable this service"), _("The service will not start until this is checked"));
        o.rmempty = false;

		o = s.taboption("general", TrimmedValue, "statsd_host", _("StatsD server hostname"),
			_("Hostname or IP address of your StatsD server"));
		o.datatype = "host";
		o.placeholder = "127.0.0.1";

		o = s.taboption("general", TrimmedValue, "statsd_port", _("StatsD server listen port"),
			_("This is normally standard"));
		o.datatype = "port";
		o.placeholder = 8125;

		o = s.taboption("general", TrimmedValue, "statsd_namespace", _("StatsD namespace to publish into"),
			_("This is the top level of all metrics from this application. You may wish to include a gateway identifier here."));
		o.placeholder = "live";

		o = s.taboption("general", form.Flag, "ignore_model", _("Ignore the cabinet model"),
			_("Select this if you wish all metrics to use the hardware ids instead of the cabinet model names."));

		return m.render();
	}
});