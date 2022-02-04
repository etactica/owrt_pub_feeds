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

		o = s.taboption("general", form.Flag, "enabled", _("Enable this service"), _("The service will not start until this is checked"));
		o.rmempty = false;

		o = s.taboption("general", TrimmedValue, "username", _("The MQTT bridge username"),
			_("Provided by SenseOne, unique for your account"));
		o.placeholder = "example-username";

		o = s.taboption("general", TrimmedValue, "password", _("The MQTT bridge password"),
			_("Provided by SenseOne, unique for your account"));
		o.placeholder = "example-private";

		o = s.taboption("general", TrimmedValue, "address", _("The MQTT broker address"),
			_("Provided by SenseOne, normally standard"));
		o.placeholder = "mqtt.senseonetech.com:8883"

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
			_("Remember, you are charged per data point, so only enable data points you're interested in."));
		o.multiple = true;
		o.optional = true;
		o.placeholder = _("Default (Active Energy)");
		o.value("+", _("Everything!"));
		o.value("cumulative_wh", _("Active Energy"));
		o.value("cumulative_varh", _("Reactive Energy"));
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

		return m.render();
	}
});
