'use strict';
'require form';
'require fs';
'require ui';
'require tools.widgets as widgets';

var desc = _(""
	+ "This service handles parsing the eTactica live stream data, and posting it to your DEXCell account."
	+ "<h4>Before you start</h4>"
	+ "You should have created a virtual gateway, and obtained your gateway Identifier/Token security pairs."
   	+ "Please see the following Dexma guides on setting these up"
   	+ "<ul>"
   	+ '<li><a href="http://support.dexmatech.com/customer/portal/articles/372837-howto-add-and-configure-a-virtual-gateway">Create a virtual gateway</a>'
  	+ '<li><a href="http://support.dexmatech.com/customer/portal/articles/1745489-howto-obtain-mac-and-token-from-a-gateway">Obtain gateway ID/Token</a>'
   	+ "</ul>"
   	+ '<h4>About Dexma <img src="/resources/images/dexma.png" width="156" height="65" style="vertical-align: middle"/></h4>'
   	+ "From their website:"
   	+ "<blockquote>"
   	+ "DEXMA Energy Intelligence is a leading provider of energy management solutions for buildings in the commercial and"
   	+ "industrial sectors. The 100% hardware-neutral, cloud SaaS tool - DEXMA Platform - combines Big Data analytics"
   	+ " with energy efficiency to help businesses and public administration Detect, Analyse and Control energy consumption,"
   	+ "become more sustainable and optimise project investment."
   	+ "</blockquote>"
  	+ '<a href="http://www.dexma.com/" target="_blank">Visit their site for more information</a>'
);

return L.view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('output-dexma', _('Output Dexma'), desc);

		s = m.section(form.TypedSection, 'general',	_("Options"));
		s.anonymous = true;

		s.tab("general", _("General Settings"));
		s.tab("advanced", _("Advanced Settings"));
		s.tab("statsd", _("StatsD"), _("Metrics on operation can be sent to a listening StatsD server, such as graphite"))

        o = s.taboption("general", form.Flag, "enabled", _("Enable this service"), _("The service will not start until this is checked"));
        o.rmempty = false;

		var key = s.taboption("general", form.Value, "source_key", _("ID for your stream"), _("This is the Identifier (MAC address) of the gateway or the unique key that identifies the datasource which the data belongs to."));
		key.placeholder = "example-public";

		var token = s.taboption("general", form.Value, "dexcell_source_token", _("The authentication token for every gateway"),
			_("This is your 'password' and is required to be able to publish to the stream."
			+ "<br>You get this from your Dexma account under the gateway settings."));
		token.placeholder = "example-private";

		var b = s.taboption("general", form.Button, "_testcred", _("Test your credentials"), _("This will attempt to validate your credentials against the server"));
        b.inputtitle = _("Test credentials");
        b.inputstyle = 'apply';
        /* sid as a param was a patch from jow, might not be available */
        b.onclick = function(ev, sid) {
            if (sid == undefined) {
                sid = Object.keys(key.data)[0];
            }
			var test_key = key.formvalue(sid);
			var test_token = token.formvalue(sid);
            console.log("and the form values are", test_key, test_token);
            var real = "https://is3.dexcell.com/readings";
            var fake = "https://192.168.253.124:8000/readings";
            var hook = "https://hookb.in/pzRZMandn1T1GKb9nrLL";
            ui.showModal(_('Testing credentials'), [
                                    E('p', { 'class': 'spinning' }, _('Contacting Dexma and testing your credentials'))
                            ]);
            var r = L.Request.request(fake, {
                method: "POST",
                content: {},
                query: {"source_key": test_key},
                headers: {
                    "x-dexcell-source-token": test_token,
                    "Content-Type": "application/json",
                }
            });
            r.then(L.bind(function(evtarget, rv) {
                console.log("ok?", evtarget, rv);
                if (rv.status == 200) {
                    console.log("credentials look good")
                    //var buttons = document.querySelectorAll(".")
                    ui.addNotification(null, E('p', _('Credentials look good!')), 'info');
                    //L.dom.append(evtarget, E('p', _('fucking magnets, how do they work')), 'info');
                    evtarget.parentNode.insertAdjacentHTML("afterEnd", "<p>Validation successful");
                    //evtarget.parentNode.insertAdjacentHTML("afterEnd", E("p", _("Validation successful")).render());
                } else {
                    console.warn("Credentials are not ok...", rv.statusText, rv.responseText)
                    evtarget.parentNode.insertAdjacentHTML("afterEnd", "<p>Validation FAILED");
                    ui.addNotification(null, E('p', _("Credentials were rejected: ") + rv.responseText), 'warning');
                }
                ui.hideModal();
            }, this, ev.target)).catch(function(e) {
                ui.addNotification(null, E('p', _("Failed to test credentials: ") + e), 'warning');
                ui.hideModal();
            });
        }

		o = s.taboption("advanced", form.ListValue, "interval", _("Interval to monitor and forward"),
			_("There's a modest bandwidth reduction to use 60minute, but it's not significant."));
		o.optional = true;
		// dexma would rather we didn't offer less than 15 minutes
		o.value("1", "1 Minute");
		o.value("5", "5 Minute");
		o.value("15", "15 Minute");
		o.value("60", "60 Minute");
		o.placeholder = "Default (15 Minute)";

		o = s.taboption("advanced", form.MultiValue, "store_types", _("Data types to store"),
			_("Remember, Dexma charges per data point, so only enable data points you're interested in."
			+ "<br>"
			+ "If you have custom variables you'd like to include, list them below under 'Custom variables'"));
		o.multiple = true;
		o.optional = true;
		o.placeholder = _("Default (Active Energy)");
		o.value("cumulative_wh", _("Active Energy"));
		o.value("cumulative_varh", _("Reactive Energy"));
		o.value("voltage", _("Voltage interval average"));
		o.value("current_mean", _("Current (interval mean)"));
		o.value("current_max", _("Current (interval maximum)"));
		o.value("pf", _("Power Factor (interval mean)"));
		o.value("temp", _("Temperature (interval mean)"));
		o.value("pulse_count", _("Pulse count"));

		o = s.taboption("advanced", form.Value, "flush_interval_ms", _("How often to attempt message flushing and/or reconnect"),
			_("This is the rate (in milliseconds) at which our message queue will be flushed to the service, and "
			+ "how often we will attempt to reconnect if the queue flush fails. You should't have to change this"));
		o.datatype = "range(5000,300000)";
		o.placeholder = 5000;

		o = s.taboption("advanced", form.Value, "limit_qd", _("Limit on queued data messages before abort"),
			_("This is how many messages will be queued and retried before the service will abort."
			+ "<p>Note, the service will be restarted periodically if it has exited, this is just how many messages to attempt "
			+ "to keep in memory while we wait for the service endpoint to come back.  A higher number allows your network to be "
			+ "offline for longer, but results in increased memory usage of your gateway, which may interfere with other services"
			)
		);
		o.datatype = "uinteger";
		o.placeholder = 2000;

		o = s.taboption("statsd", form.Value, "statsd_namespace", _("Namespace for StatsD reporting"))
		o.placeholder = "apps.output-db.<instanceid>"
		o.optional = true

		o = s.taboption("statsd", form.Value, "statsd_host", _("Hostname to send stats"))
		o.placeholder = "localhost"
		o.datatype = "host"
		o.optional = true

		o = s.taboption("statsd", form.Value, "statsd_port", _("UDP port to send stats"))
		o.placeholder = 8125
		o.datatype = "port"
		o.optional = true

		s = m.section(form.GridSection, "customvar", _("Custom Parameters"),
			_("Custom mappings of data stream variables to Dexma Parameter IDs not handled automatically"));
		s.modaltitle = _("Add new custom Dexma variable mapping");
		s.anonymous = true;
		s.addremove = true;
		s.sortable = true;

		/* Dexma values we need:
		- string to match on data stream
		- string from list to choose field in interval data
		- float for scale factor
		- raw positive integer for dexma parameter
		 */

		o = s.option(form.Flag, "enabled", _("Enabled"));
		// really? o.editable = true;
		o = s.option(form.Value, "datakey", _("Datakey"), _("The name of the datatype in the aggregate stream"));
		o.rmempty = false;
		o = s.option(form.ListValue, "field", _("Field"), _("Which field of the aggregate to select"));
		o.value("mean", "Mean");
		o.value("max", "Maximum");
		o.value("min", "Minimum");
		o.value("stddev", "Standard Deviation");
		/* Do we care about min/max ts? or start/end ts? */
		o = s.option(form.Value, "multiplier", _("Multiplier"), _("Multiplier to apply before sending to Dexma"));
		o.datatype = "float";
		o = s.option(form.Value, "parameterid", _("Dexma Parameter ID"), _("Parameter ID from Dexma's API documentation"));
		o.datatype = "uinteger";
		o.rmempty = false;


		return m.render();
	}
});