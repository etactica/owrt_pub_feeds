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

		o = s.option(form.Flag, "enabled", _("Enable this service"), _("The service will not start until this is checked"));
		o.rmempty = false;

		o = s.option(TrimmedValue, "username", _("The MQTT bridge username"),
			_("Provided by SenseOne, unique for your account"));
		o.placeholder = "example-username";

		o = s.option(TrimmedValue, "password", _("The MQTT bridge password"),
			_("Provided by SenseOne, unique for your account"));
		o.placeholder = "example-private";

		o = s.option(TrimmedValue, "address", _("The MQTT broker address"),
			_("Provided by SenseOne, normally standard"));
		o.placeholder = "mqtt.senseonetech.com:8883"

		return m.render();
	}
});