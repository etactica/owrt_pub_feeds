// Sample "monitor" page, has a mqtt

function StateMessageSimple(ts, topic, raw) {
    var self = this;
    self.ts = ko.observable(ts);
    self.topic = ko.observable(topic);
    self.raw = ko.observable(raw);
}

function PageModel() {
    var self = this;
    self.errNotSupported = ko.observable(false);
    self.errNotConnected = ko.observable(false);
    self.messages = ko.observableArray();
    self.subscription = ko.observable();
    self.subscriptions = ko.observableArray();

    self.subscribe = function() {
        console.log("attempting to subscribe");
        self.mqclient.subscribe(self.subscription(), {
            qos: 0, onFailure: self.wsSubFail
        });
        self.subscriptions.push(self.subscription());
    }

    self.unsubscribe = function(a) {
        self.mqclient.unsubscribe(a);
        self.subscriptions.remove(a);
    }

    self.start = function() {
        try {
            self.mqclient = new Paho.MQTT.Client(location.hostname, 8083,
                "mqtt-mon-monitor-" + (Math.random() + 1).toString(36).substring(2,8));
            self.mqclient.onConnectionLost = self.wsLostHandler;
            self.mqclient.onMessageArrived = self.wsOnMessage;
            self.wsDoConnect();
        } catch (e) {
            self.errNotSupported(true);
        }
    };

    self.wsSubFail = function (obj) {
        self.mqclient.disconnect();
        setTimeout(self.wsDoConnect, 5000);
    }

    self.wsOnMessage = function(message) {
        var payload = JSON.parse(message.payloadString);
        if (!payload) {
            console.log("shouldn't happen, getting sent invalid json on topic: " + message.destinationName);
            return;
        }
        //var msg = new StateMessage(payload)
        // TODO - richer parsing?
        var msg = new StateMessageSimple(new Date(), message.destinationName, message.payloadString);
        console.log(`Received on ${msg.topic()}`, payload)
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

//        self.mqclient.subscribe("status/local/json/applications/mqtt-mon/state", {
//            qos: 0, onFailure: subFail
//        });
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