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
    console.warn(obj.errorMessage);
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
        if (self.hwc_attempts == null) {
            self.hwc_attempts = 0
        }
        self.hwc_attempts = self.hwc_attempts + 1;
        setTimeout(function() {
            if (!self.hwc) {
                request_hwc();
            }
        }, 2500);
    }

    self.mqclient.subscribe("status/+/json/modbusdevicemodel/#", {
      qos: 0, onFailure: subFail
    });
    request_hwc();
}

var WsDoConnect = function() {
    self.mqclient.connect({
        mqttVersion: 4,
        onFailure: WsLostHandler,
        onSuccess: WsConnected,
        useSSL: window.location.protocol === "https:"
    });
}

var WsOnMessage = function(message) {
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

    if (topics[3] === "modbusdevicemodel") {
        self.hwc = payload;
    }

}

return L.view.extend({

    load: function() {
        Promise.all(['/resources/paho/mqttws31.js', '/resources/product_codes.jsonp'].map(function(src) {
                return new Promise(function(resolveFn, rejectFn) {
                    document.querySelector('head').appendChild(E('script', {
                        src: src,
                        load: resolveFn,
                        error: rejectFn
                }));
            })
        }))
        .then(function(a) {
            self.mqclient = new Paho.MQTT.Client(location.hostname, 8083,
                            "io-charging-on-cfgUI-" + (Math.random() + 1).toString(36).substring(2,8));
            self.mqclient.onConnectionLost = WsLostHandler;
            self.mqclient.onMessageArrived = WsOnMessage;
            WsDoConnect();
        })
        .catch(function(a) {
            console.error("failed to load and initialize...? try reloading the page?", a)
        });
        // Wait here until the hwc is loaded.
        var waitForHWC = function(resolve, reject) {
            if (self.hwc) {
                resolve(self.hwc);
            } else {
                    if (self.hwc_attempts >= 3) {
                        console.log("Giving up and falling back to static config");
                        //reject("gave up?");
                        // Fake out a blank response
                        self.hwc = {}
                        //ui.addNotification(null, E('p', _('Fetching the Hardware Config has failed %d times, are devices configured?').format(self.hwc_attempts)));
                        //ui.showIndicator(123, _("Waiting on HWC"));
                    }
                setTimeout(function(x) {
                    waitForHWC(resolve, reject)
                }, 500);
            }
            // TODO if (self.hwc_attempts > 1) { make a warning element somewhere and insert it to say we're waiting? }
            // followup, if you insert it, make sure to remove/hide it when you get the hwc.
        }
        return new Promise(waitForHWC);
    },

    hwc_attempts: 0,
    wsLostHandler: WsLostHandler,
    wsConnected: WsConnected,
    wsDoConnect: WsDoConnect,
    wsOnMessage: WsOnMessage,

	render: function(hwc) {
		var m, s, o;
		// TODO - if loadresults is empty, and we've got the right warning text from the load(), then just let people enter ids?

		m = new form.Map('io-charging-on', _('IO Charging ON.is'), desc);

		s = m.section(form.TypedSection, 'general',	_("Options"));
		s.anonymous = true;

		s.tab("general", _("General Settings"));
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

		var key = s.taboption("general", TrimmedValue, "mains_size", _("Mains size (Amps)"),
			_("The assigned capacity of the mains supply."));
		key.placeholder = "400";

        var foundValid = false;
        var mmeter;
        var chargers;
        if (hwc && hwc.devices && hwc.devices.length > 0) {
            // Provide all known devices as pick options for mains + chargers
            for (var i = 0; i < hwc.devices.length; i++) {
                var d = hwc.devices[i];
                if (d.deviceid != null) {
                    if (mmeter == null) {
                        mmeter = s.taboption("general", form.Value, "mains_id", _("Mains ID"),
                                        _("Identifier of the mains meter"));
                        mmeter.optional = false;
                        mmeter.placeholder = "Serial of meter, from plugin, eg 23523452";
                    }
                    if (chargers == null) {
                        chargers = s.taboption("general", form.MultiValue, "charger_ids", _("Charger IDs"),
                                        _("Identifiers of each charger to handle"));
                        chargers.optional = true;
                        chargers.placeholder = _("Pick all charger units");
                    }
                    // et devices have product codes, not names...
                    var pName = d.productName;
                    if (pName == null && d.vendor == 21069) {
                        var prod = product_map(d.product);
                        if (prod && prod.name) {
                            pName = prod.name;
                        }
                    }
                    mmeter.value(d.deviceid, d.deviceid + ": " + d.vendorName + " " + pName + " @ " + d.mbDevice + "/" + d.slaveId + " (" + d.pluginName + ")");
                    chargers.value(d.deviceid, d.deviceid + ": " + d.vendorName + " " + pName + " @ " + d.mbDevice + "/" + d.slaveId + " (" + d.pluginName + ")");
                    // TODO - warn the user if they have _some_ devices with no deviceid? they might have partial config available?
                    foundValid = true;
                }
            }
        }
        if (!foundValid) {
            // No hwc, or hwc, but no-valid devices, require static config!
            o = s.taboption("general", form.DummyValue, '_dummy', _('Status'));
            o.render = function(section_id) {
                // TODO - styling could be better?
                var hwcWarning = E([], [
                    E('h5', [ _('No Hardware config found, or no valid devices, static configuration only!') ]),
                    E('p', [_("If all modbus devices have been configured and detected, we can provide an automatic"
                     + " list here.  As the hardware configuration couldn't be loaded, only static entries are available!"),
                        E('ul', [
                            E('li', _('Check that all devices are reachable!')),
                            E('li', _('Check that you have configured devices!')),
                        ])
                     ])
                ]);
                return hwcWarning;
            };

            mmeter = s.taboption("general", TrimmedValue, "mains_id", _("Mains ID"),
                _("Identifier of the mains meter"));
            mmeter.optional = false;
            mmeter.placeholder = "Serial of meter, from plugin, eg 23523452";

            chargers = s.taboption("general", form.DynamicList, "charger_ids", _("Charger IDs"),
                                         _("Identifiers of each charger to handle"));
            chargers.optional = true;
            chargers.placeholder = _("Serials of all chargers, from plugin, eg 234325443");
        }


		o = s.taboption("statsd", TrimmedValue, "statsd_namespace", _("Namespace for StatsD reporting"))
		o.placeholder = "io-charging-on"
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