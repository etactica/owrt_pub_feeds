
function StateMessageSimple(ts, raw) {
    var self = this;
    self.ts = ko.observable(ts);
    self.raw = ko.observable(raw);
}

function PageModel() {
    var self = this;
    self.errNotSupported = ko.observable(false);
    self.errNotConnected = ko.observable(false);
    self.messages = ko.observableArray();

    self.start = function() {
        try {
            self.mqclient = new Paho.MQTT.Client(location.hostname, 8083,
                "io-charging-on-monitor-" + (Math.random() + 1).toString(36).substring(2,8));
            self.mqclient.onConnectionLost = self.wsLostHandler;
            self.mqclient.onMessageArrived = self.wsOnMessage;
            self.wsDoConnect();
        } catch (e) {
            self.errNotSupported(true);
        }
    };

    self.wsOnMessage = function(message) {
        var payload = JSON.parse(message.payloadString);
        if (!payload) {
            console.log("shouldn't happen, getting sent invalid json on topic: " + message.destinationName);
            return;
        }
        console.log("received a new state message: ", payload)
        //var msg = new StateMessage(payload)
        // TODO - richer parsing?
        var msg = new StateMessageSimple(new Date(), message.payloadString);
        self.messages.unshift(msg);
        if (self.messages().length > 50) {
            self.messages(self.messages().slice(0,50));
        }
    };

    self.wsLostHandler = function(obj) {
        self.errNotConnected(obj.errorMessage);
        setTimeout(self.wsDoConnect, 5000);
    };

    self.wsConnected = function(obj) {
        self.errNotConnected(false);
        function subFail(obj) {
            self.mqclient.disconnect();
            setTimeout(self.wsDoConnect, 5000);
        }

        self.mqclient.subscribe("status/local/json/applications/io-charging-on/state", {
            qos: 0, onFailure: subFail
        });
    };

    self.wsDoConnect =function() {
        self.mqclient.connect({
            mqttVersion: 4,
            onFailure: self.wsLostHandler,
            onSuccess: self.wsConnected,
            useSSL: window.location.protocol === "https:"
        });
        self.errNotConnected(false);
    };

}

document.addEventListener("DOMContentLoaded", function(event) {
    mymodel = new PageModel();
    mymodel.start();
    ko.applyBindings(mymodel);
});

window.addEventListener('beforeunload', function() {
	mymodel.mqclient.onConnectionLost = function() {};
})
