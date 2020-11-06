'use strict';
'require form';
'require fs';
'require ui';
'require tools.widgets as widgets';

var desc = _(""
	+ "This service handles monitoring a mains meter, and <em>N</em> connected EV charging stations. "
	+ "The available power, after accounting for other consumers, is written to the connected chargers, providing "
	+ "dynamic load control. This implementation and algorithm is tailored for Orku náttúrunnar, an Icelandic utility, but may be useful for others."
	+ "<h4>Before you start</h4>"
	+ "<ul>"
 	+ "<li>You should have configured all the connected chargers on <a href='"+ L.url("home/wizard/simple_config") + "'>Config Devices</a>"
	+ "<li>You should have determined the actual allocated available power on the mains"
   	+ "</ul>"
   	+ '<h4>About Orku náttúrunnar <img src="/resources/images/ON-n-texta.png" width="135" height="65" style="vertical-align: middle"/></h4>'
   	+ "From their website:"
   	+ "<blockquote>"
   	+ "ON Power produces and sells electricity to the entire population and hot water to the capital area. "
    + "The objective is to protect the interests of the country’s natural resources and the company’s customers, guided "
    + "by the principle of sustainability. In so doing, the company supports innovation and the responsible utilisation "
    + "of natural resources and promotes energy switching to a lower ecological footprint for the benefit of society as a whole."
   	+ "</blockquote>"
  	+ '<a href="http://www.on.is/" target="_blank">Visit their site for more information</a>'
);

var TrimmedValue = form.Value.extend({
	write: function(sid, formvalue) {
		this.super("write", [sid, formvalue.trim()]);
	}
})

var WsLostHandler = function(obj) {
    console.warning(obj.errorMessage);
    setTimeout(self.wsDoConnect, 5000);
};

var WsConnected = function(obj) {
    function subFail(obj) {
      self.mqclient.disconnect();
      setTimeout(self.wsDoConnect, 5000);
    }

    function request_hwc() {
      var m = new Paho.MQTT.Message("{}");
      m.destinationName = "command/local/json/getmodbusdevicemodel";
      self.mqclient.send(m);
      self.hwc_attempts = self.hwc_attempts + 1;
      setTimeout(function() {
          if (!self.hwc_received) {
              request_hwc();
          }
      }, 5000);
    }

    self.mqclient.subscribe("status/+/json/modbusdevicemodel/#", {
      qos: 0, onFailure: subFail
    });
    request_hwc();
    // For the logical cabinet information
    self.mqclient.subscribe("status/+/json/cabinet/#", {
      qos: 0, onFailure: subFail
    });
    // For the data
    self.mqclient.subscribe("status/+/json/device/#", {
      qos: 0, onFailure: subFail
    });
}

var WsDoConnect = function() {
    self.mqclient.connect({
        mqttVersion: 4,
        onFailure: WsLostHandler,
        onSuccess: WsConnected,
        useSSL: window.location.protocol === "https:"
    });
    //self.errNotConnected(false);
}

var WsOnMessage = function(message) {
    console.log("woop: ", message.destinationName);
    var topics = message.destinationName.split("/");
    if (topics.length < 1) {
      console.log("shouldn't happen, ignoring message on topic: " + message.destinationName);
      return;
    }
    var payload = JSON.parse(message.payloadString);
    if (!payload) {
      console.log("shouldn't happen, getting sent invalid json on topic: " + message.destinationName);
      return;
    }
}

return L.view.extend({

    load: function() {
        console.log("load called");
        return Promise.all(['/resources/paho/mqttws31.js'].map(function(src) {
                return new Promise(function(resolveFn, rejectFn) {
                    document.querySelector('head').appendChild(E('script', {
                        src: src,
                        load: resolveFn,
                        error: rejectFn
                }));
            })
        }));
    },

    hwc_attempts: 0,
    hwc_received: false,
    wsLostHandler: WsLostHandler,
    wsConnected: WsConnected,
    wsDoConnect: WsDoConnect,
    wsOnMessage: WsOnMessage,

	render: function(loadresults) {
		var m, s, o;
		console.log("loadresults are...", loadresults);


		self.mqclient = new Paho.MQTT.Client(location.hostname, 8083,
                        "chanmon-" + (Math.random() + 1).toString(36).substring(2,8));
        self.mqclient.onConnectionLost = WsLostHandler;
        self.mqclient.onMessageArrived = WsOnMessage;
        WsDoConnect();  // this is going to go bang too


		m = new form.Map('io-charging-on', _('IO Charging ON.is'), desc);

		s = m.section(form.TypedSection, 'general',	_("Options"));
		s.anonymous = true;

		s.tab("general", _("General Settings"));
		s.tab("advanced", _("Advanced Settings"));
		s.tab("statsd", _("StatsD"), _("Metrics on operation can be sent to a listening StatsD server, such as graphite"))

        o = s.taboption("general", form.Flag, "enabled", _("Enable this service"), _("The service will not start until this is checked"));
        o.rmempty = false;

    // maybe?
//		o = s.taboption("general", form.DummyValue, "_linkbutton", _("Runtime diagnostics"), _("Displays more detailed information about the state of the service"));
//		o.href = L.url("admin/services/output-dexma/diags2");
//		o.cfgvalue = function(s) {
//			return _("Runtime diagnostics");
//		};
//		o.depends("enabled", "1");

		var key = s.taboption("general", TrimmedValue, "mains_size", _("Mains size"),
			_("The assigned capacity of the mains supply."));
		key.placeholder = "400";

        // FIXME- classically, we've done just modbus lists here... but... can we expect this to be probed already?
		var token = s.taboption("general", TrimmedValue, "mains_id", _("Mains ID"),
			_("Identifier of the Mains meter"));
		token.placeholder = "1234568 (fixme, dropdown from model?)";

        // otherwise, this whole section becomes pairs of host/port/(optional?)unitids
		o = s.taboption("advanced", form.MultiValue, "charger_ids", _("Charger IDs"),
			_("Identifiers of each charger to handle"));
		o.multiple = true;
		o.optional = true;
		o.placeholder = _("FIXME - picklist from model");
		o.value("id111", _("111"));
		o.value("id222", _("222"));


		o = s.taboption("statsd", TrimmedValue, "statsd_namespace", _("Namespace for StatsD reporting"))
		o.placeholder = "apps.io-charging-on"
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