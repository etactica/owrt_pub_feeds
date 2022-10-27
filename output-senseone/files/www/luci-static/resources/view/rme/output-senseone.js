'use strict';
'require form';
'require fs';
'require ui';
'require tools.widgets as widgets';

var desc = _(""
    + "This service handles bridging eTactica live stream data, and posting it to your SenseOne account."
    + "<h4>Before you start</h4>"
    + "You should <em>already</em> have an SenseOne account."
    + "<h4>More information</h4>"
    + "<p/>"
    + "From their website:"
    + "<blockquote>"
    + "<p>At SenseOne, our vision is to deliver IoT solutions that exceed customer’s expectations."

    + "<p>We came to work on the Internet of Things from on the ground challenges to connect assets and systems inside commercial and industrial buildings."

    + "<p>From a business standpoint, we have created an IoT middleware platform that is capable of reducing the lifecycle cost and effort of multiple integrations that are central to any IoT implementation."

    + "<p>From a technical standpoint, we have focused on interoperability requirements and developed a scalable IoT middleware layer for integrating heterogeneous systems and enabling connected environments."
    + "</blockquote>"
    + "<p/>"
    + "<a href='https://www.senseone.io/' target='_blank'>"
    + "    <img src='/resources/images/senseone.png' height='31' style='vertical-align: middle' alt='SenseOne logo'/><br>"
    + "    Visit their site for more information"
    + "</a>"
    + "</p>"
);

var TrimmedValue = form.Value.extend({
    write: function(sid, formvalue) {
        this.super("write", [sid, formvalue.trim()]);
    }
})

return L.view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('output-senseone', _('Output SenseOne'), desc);

		s = m.section(form.TypedSection, 'general',	_("Options"));
		s.anonymous = true;

		s.tab("general", _("General Settings"));
		s.tab("advanced", _("Advanced Settings"));
		s.tab("statsd", _("StatsD"));

		o = s.taboption("general", form.Flag, "enabled", _("Enable this service"), _("The service will not start until this is checked"));
		o.rmempty = false;

		var user = s.taboption("general", TrimmedValue, "username", _("The MQTT bridge username"),
			_("Provided by SenseOne, unique for your account"));
		user.placeholder = "example-username";

		var password = s.taboption("general", TrimmedValue, "password", _("The MQTT bridge password"),
			_("Provided by SenseOne, unique for your account"));
		password.placeholder = "example-private";

		var host = s.taboption("general", TrimmedValue, "address", _("The MQTT broker address"),
			_("Provided by SenseOne, normally standard"));
		host.placeholder = "mqtt.senseonetech.com:8883";

		var b = s.taboption("general", form.Button, "_testcred", _("Test your credentials"), _("This will attempt to validate your credentials with SenseOne"));
        b.inputtitle = _("Test credentials");
        b.inputstyle = 'apply';
        b.onclick = function(ev, sid) {
            var btn = ev.target;
            btn.classList.add('spinning');
			var test_user = user.formvalue(sid);
			var test_password = password.formvalue(sid);
			var test_host = host.formvalue(sid)
			var node_user = m.findElement('id', user.cbid(sid));
			var node_password = m.findElement('id', password.cbid(sid));
			var node_host = m.findElement('id', host.cbid(sid));
			var is_insecure = (insecure.formvalue(sid) == "1");

            var clearResults = function(tgt) {
	            while (node_user.firstChild.nextSibling) { node_user.firstChild.nextSibling.remove() }
	            while (node_password.firstChild.nextSibling) { node_password.firstChild.nextSibling.remove() }
	            while (node_host.firstChild.nextSibling) { node_host.firstChild.nextSibling.remove() }
                while (tgt.nextSibling) {
                    tgt.nextSibling.remove();
                }
            }
            clearResults(btn);

            // This is the way we inject commands, hi ho, hi ho....
            // but.... if you are logged in with access here, you could just be calling fs.exec yourself....
            var protocol = "mqtts"
            if (is_insecure) {
                protocol = "mqtt"
            }
            var real = `${protocol}://${test_user}:${test_password}@${test_host}/test/validate_credentials`;
            if (test_password.length == 0) {
                real = `${protocol}://${test_host}/test/validate_credentials`;
            }
            ui.showModal(_('Testing credentials'), [ E('p', { 'class': 'spinning' }, _('Contacting SenseOne and testing your credentials')) ]);
            var markError = function(tgt, descr, details) {
                node_user.firstChild.classList.add("cbi-input-invalid");
                node_password.firstChild.classList.add("cbi-input-invalid");
                node_host.firstChild.classList.add("cbi-input-invalid");
                var cross = E('span', { 'class': "check-fail" }, "✘");
                tgt.insertAdjacentElement("afterEnd", E("div", [E("h6", {class: "alert-message"}, descr), E("pre", details)]));
                tgt.insertAdjacentElement("afterEnd", cross);
            };
            var args = ["-L", real, "-E"];
            if (!is_insecure) {
                args.push("--cafile", "/etc/ssl/certs/senseonetech-mqtt.crt")
            }
            var r = fs.exec("mosquitto_sub", args);
            r.then(L.bind(function(evtarget, rv) {
                if (rv.code == 0) {
                    // if the pub succeeded, we're definitely good
		            node_user.firstChild.classList.remove("cbi-input-invalid");
		            node_password.firstChild.classList.remove("cbi-input-invalid");
		            node_host.firstChild.classList.remove("cbi-input-invalid");
                    var tick = E('span', { 'class': "check-ok" }, "✓");
                    node_user.insertAdjacentElement("beforeEnd", tick);
                    node_password.insertAdjacentElement("beforeEnd", tick.cloneNode(true));
                    node_host.insertAdjacentElement("beforeEnd", tick.cloneNode(true));
                    evtarget.insertAdjacentElement("afterEnd", E("h6", _("Validation successful")));
                } else {
                    // mosquitto_pub itself failed.  stderr now has the useful error, not the progress meter.
                    markError(evtarget, _("Failed to test credentials: " + rv.code), rv.stderr);
                }
                ui.hideModal();
            }, this, ev.target), function(rv) {
                // You land here if the XHR times out, for instance.
                markError(ev.target, _("Failed to test credentials"), rv.message);
                ui.hideModal();
            }
            ).catch(function(e) {
                // This is an unexpected internal failure, try again?
                ui.addNotification(null, E('p', _("Failed to test credentials, perhaps try again?: ") + e), 'warning');
                ui.hideModal();
            });
        }


		o = s.taboption("advanced", form.ListValue, "interval", _("Interval to monitor and forward"),
			_("There's a modest bandwidth reduction to use 60minute, but it's not significant."));
		o.optional = true;
		// Senseone would rather we didn't offer less than 15 minutes
		//o.value("1min", "1 Minute");
		//o.value("5min", "5 Minute");
		o.value("15min", "15 Minute");
		o.value("60min", "60 Minute");
		o.placeholder = "Default (15 Minute)";

		o = s.taboption("advanced", form.DynamicList, "store_types", _("Data types to store"),
			_("Remember, you are charged per data point, so only enable data points you're interested in." +
			  "<br>For custom datapoints, enter the mqtt metric name, eg <tt>energy_wh_in</tt>.  " +
			  "<br>For remapping points to a different value enter in the form <tt>mqtt_metric_in=mqtt_metric_out</tt>"));
		o.multiple = true;
		o.optional = true;
		o.placeholder = _("Default (Active Energy)");
		o.value("+", _("Everything!"));
		o.value("cumulative_wh", _("Active Energy (from cumulative)"));
		o.value("cumulative_varh", _("Reactive Energy"));
		o.value("energy_in_wh", _("Active Energy Import"));
		o.value("energy_out_wh", _("Active Energy Export"));
		o.value("energy_in_wh=cumulative_wh", _("Active Energy Import (report as cumulative)"));
		o.value("volt", _("Voltage"));
		o.value("current", _("Current"));
		o.value("pf", _("Power Factor"));
		o.value("frequency", _("Frequency"));
		o.value("power", _("Power"));
		o.value("temp", _("Temperature"));
		o.value("pulse_count", _("Pulse count"));
		o.value("humidity", _("Humidity"));
		o.value("dewpoint", _("Dew Point"));
		o.editable = true;

		o = s.taboption("advanced", form.Flag, "include_gateid", _("Include Gateway ID in bridge topics"),
			_("This allows the same modbus addresses to be re-used with an account, but should only be " +
			"enabled after confirming your account is configured for this with SenseOne"));
		o = s.taboption("advanced", form.Flag, "_show_developer", _("Show developer debugging"),
			_("Shows some developer debug options that should never be needed in normal use"));
		o.write = function() {};
		var insecure = s.taboption("advanced", form.Flag, "insecure", _("Don't use TLS for MQTT connections"),
			_("This should only be used when testing with local replacements for senseone"));
		insecure.depends("_show_developer", "1");


		o = s.taboption("statsd", TrimmedValue, "statsd_namespace", _("Namespace for StatsD reporting"))
		o.placeholder = "apps.output-senseone"
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
