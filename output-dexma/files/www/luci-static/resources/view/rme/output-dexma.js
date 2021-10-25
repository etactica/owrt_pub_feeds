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

var TrimmedValue = form.Value.extend({
	write: function(sid, formvalue) {
		this.super("write", [sid, formvalue.trim()]);
	}
})

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

		o = s.taboption("general", form.DummyValue, "_linkbutton", _("Runtime diagnostics"), _("Displays more detailed information about the state of the service"));
		o.href = L.url("admin/services/output-dexma/diags2");
		o.cfgvalue = function(s) {
			return _("Runtime diagnostics");
		};
		o.depends("enabled", "1");

		var key = s.taboption("general", TrimmedValue, "source_key", _("Key"),
			_("This is the <em>identifier</em> of the gateway you chose when you created the gateway in your Dexma account."
			+ "<br>This is in your Dexma account on the gateway settings page as <em>Key</em>."));
		key.placeholder = "example-public";

		var token = s.taboption("general", TrimmedValue, "dexcell_source_token", _("Gateway token"),
			_("This is your <em>password</em> and is required to be able to publish to the stream."
			+ "<br>This is in your Dexma account on the gateway settings page as <em>Gateway token</em>."));
		token.placeholder = "example-private";

		var b = s.taboption("general", form.Button, "_testcred", _("Test your credentials"), _("This will attempt to validate your credentials with Dexma"));
        b.inputtitle = _("Test credentials");
        b.inputstyle = 'apply';
        b.onclick = function(ev, sid) {
            var btn = ev.target;
            btn.classList.add('spinning');
			var test_key = key.formvalue(sid);
			var test_token = token.formvalue(sid);
			var node_key = m.findElement('id', key.cbid(sid));
			var node_token = m.findElement('id', token.cbid(sid));

            var clearResults = function(tgt) {
	            while (node_key.firstChild.nextSibling) { node_key.firstChild.nextSibling.remove() }
	            while (node_token.firstChild.nextSibling) { node_token.firstChild.nextSibling.remove() }
                while (tgt.nextSibling) {
                    tgt.nextSibling.remove();
                }
            }
            clearResults(btn);

            var real = "https://is3.dexcell.com/readings";
            ui.showModal(_('Testing credentials'), [ E('p', { 'class': 'spinning' }, _('Contacting Dexma and testing your credentials')) ]);
            // This is the way we inject commands, hi ho, hi ho....
            // but.... if you are logged in with access here, you could just be calling fs.exec yourself....
            // Dexma doesn't allow CORS (bug filed) so we do it on the server
            var r = fs.exec("curl", [real + "?source_key=" + test_key, "-H", "x-dexcell-source-token: " + test_token,
                "-H", "Content-type: application/json", "-d", "[]", "-m", "15"]);
            r.then(L.bind(function(evtarget, rv) {
                // Dexma's api is plain text in the responses, and a mix of http codes.
                // we can't separate the response and the http code from curl without using an output file, and if
                // we do that, curl insists on printing a progress bar.  If we use -s to silence the progress bar,
                // we no longer get meaningful error messages on timeouts or network failures.
                // => so, we string parse the responses from dexma :(
                var markError = function(tgt, descr, details) {
                    node_key.firstChild.classList.add("cbi-input-invalid");
                    node_token.firstChild.classList.add("cbi-input-invalid");
                    var cross = E('span', { 'class': "check-fail" }, "✘");
					tgt.insertAdjacentElement("afterEnd", E("div", [E("h6", {class: "alert-message"}, descr), E("pre", details)]));
                    tgt.insertAdjacentElement("afterEnd", cross);
                };
                if (rv.code == 0) {
                    // curl succeeded, so stdout has the good/bad dexma reply, and stderr is a useless progress meter.
                    if (rv.stdout.indexOf("OK") == 0) {
			            node_key.firstChild.classList.remove("cbi-input-invalid");
			            node_token.firstChild.classList.remove("cbi-input-invalid");
	                    var tick = E('span', { 'class': "check-ok" }, "✓");
	                    node_key.insertAdjacentElement("beforeEnd", tick);
	                    node_token.insertAdjacentElement("beforeEnd", tick.cloneNode(true));
	                    evtarget.insertAdjacentElement("afterEnd", E("h6", _("Validation successful")));
                    } else {
	                    markError(evtarget, _("Credentials were rejected: "), rv.stdout);
                    }
                } else {
                    // curl itself failed.  stderr now has the useful error, not the progress meter.
                    markError(evtarget, _("Failed to test credentials: "), rv.stderr);
                }
                ui.hideModal();
            }, this, ev.target), function(rv) { console.log("Rejected promise handler? How would this be reached?", rv)}
            ).catch(function(e) {
                // This is an unexpected internal failure, try again?
                ui.addNotification(null, E('p', _("Failed to test credentials, perhaps try again?: ") + e), 'warning');
                ui.hideModal();
            });
        }

		o = s.taboption("advanced", form.ListValue, "interval", _("Interval to monitor and forward"),
			_("There's a modest bandwidth reduction to use 60minute, but it's not significant."));
		o.optional = true;
		// dexma would rather we didn't offer less than 15 minutes
		//o.value("1", "1 Minute");
		//o.value("5", "5 Minute");
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
		o.value("voltage", _("Voltage (interval mean)"));
		o.value("current_mean", _("Current (interval mean)"));
		o.value("current_max", _("Current (interval maximum)"));
		o.value("pf", _("Power Factor (interval mean)"));
		o.value("temp", _("Temperature (interval mean)"));
		o.value("pulse_count", _("Pulse count"));
		o.value("power_mean", _("Power (interval mean)"));
		o.value("power_max", _("Power (interval maximum)"));

		o = s.taboption("advanced", form.Value, "flush_interval_ms", _("How often to attempt message flushing and/or reconnect"),
			_("This is the rate (in milliseconds) at which our message queue will be flushed to the service, and "
			+ "how often we will attempt to reconnect if the queue flush fails. You should't have to change this"));
		o.datatype = "range(500,300000)";
		o.placeholder = 500;

		o = s.taboption("advanced", form.Value, "limit_qd", _("Limit on queued interval data messages before abort"),
			_("This is how many intervals of  messages will be queued and retried before the service will abort."
			+ "<p>Note, the service will be restarted periodically if it has exited, this is just how many messages to attempt "
			+ "to keep in memory while we wait for the service endpoint to come back.  A higher number allows your network to be "
			+ "offline for longer, but results in increased memory usage of your gateway, which may interfere with other services."
			+ "For 15 minute intervals, the default is about 5 days worth of data."
			)
		);
		o.datatype = "uinteger";
		o.placeholder = 500;

		o = s.taboption("advanced", form.Value, "url_template", _("Override the Dexma Insertion API endpoint"),
			_("This should only be used for development and debugging!"));
		o.placeholder = "https://is3.dexcell.com/readings?source_key=%s";
		o.optional = true;

		o = s.taboption("statsd", TrimmedValue, "statsd_namespace", _("Namespace for StatsD reporting"))
		o.placeholder = "apps.output-dexma"
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
		o = s.option(TrimmedValue, "datakey", _("Datakey"), _("The name of the datatype in the aggregate stream"));
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