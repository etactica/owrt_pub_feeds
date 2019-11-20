'use strict';
'require form';
'require fs';
'require tools.widgets as widgets';

return L.view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('output-db', _('Output DB'), _('Output-DB offers a basic method of writing basic interval data to a given generic SQL database'));

		s = m.section(form.TypedSection, 'instance', _('Instances'),
			_("You can run multiple instances of this service.  Choose a name and click 'Add' to make a new instance")
		);
		s.addremove = true;

		s.tab("general", _("General Settings"));
		s.tab("advanced", _("Advanced Settings"));

        o = s.taboption("general", form.Flag, "enabled", _("Enable this instance"), _("The service will not start until this is checked"));
        o.rmempty = false;

		/* We actually need to know what driver to use, because luasql doesn't do that on a magic connection url, but params on the drivers */
		o = s.taboption("general", form.ListValue, "driver", _("Database driver"), _("What sort of database are we connecting to?"));
		o.value('postgres', _('Postgres'));
		o.value('mysql', _('MySQL/MariaDB'));

		o = s.taboption("general", form.Value, "dbname", _("Database name"), _("The name of the database you wish to connect to"))
		o.placeholder = "datasink"

		o = s.taboption("general", form.Value, "dbuser", _("Database username"), _("The username to use when connecting to the database"))
		o.placeholder = "some-user-name"

		o = s.taboption("general", form.Value, "dbpass", _("Database password"), _("The password for your database user"))
		o.placeholder = "some-db-password"
		o.password = true;

		o = s.taboption("general", form.Value, "dbhost", _("Database hostname"), _("Hostname of your database server"))
		o.placeholder = "my-db-instance.some-zone.rds.amazonws.com"
		o.datatype = "host"

		o = s.taboption("general", form.Value, "dbport", _("Database port"), _("Port your database server runs on. You can normally leave this blank"))
		o.placeholder = _("default")
		o.datatype = "port"

		o = s.taboption("advanced", form.ListValue, "interval", _("Interval to monitor and forward"), _("Default is 15 minute, but you can select finer/coarser grained"));
		o.optional = true;
		o.value("1", "1 Minute");
		o.value("5", "5 Minute");
		o.value("15", "15 Minute");
		o.value("60", "60 Minute");
		o.placeholder = "Default (15 Minute)";

		o = s.taboption("advanced", form.MultiValue, "store_types", _("Data types to store"));
		o.multiple = true;
		o.optional = true;
		o.placeholder = _("Default (Active Energy)");
		o.value("_all", _("All types seen"))
		o.value("cumulative_wh", _("Active Energy"));
		o.value("cumulative_varh", _("Reactive Energy"));
		o.value("voltage", _("Voltage"));
		o.value("current", _("Current"));
		o.value("pf", _("Power Factor"));
		o.value("frequency", _("Frequency"));
		o.value("temp", _("Temperature"));
		o.value("flownet", _("Net Flow (m³)"))
		o.value("flowrate", _("Flow rate (m³/h)"))
		o.value("pulsecount", _("Pulse count"))

		var originals = {};
		var load_q = function(sid, qtype) {
			var custom_fn = "/etc/output-db/custom." + sid + "." + qtype + ".query";
			var custom = fs.trimmed(custom_fn);
			var def = fs.trimmed("/usr/share/output-db/default." + qtype + ".query");
			return Promise.all([custom, def]).then(function(values) {
				var content = values.find(function(v) {return v.length > 0}) || "Neither custom nor default file could be loaded?";
				var key = sid + qtype;
				originals[key] = content;
				return content;
			});
		}

		var save_q = function(sid, qtype, value, oldwrite) {
			var custom_fn = "/etc/output-db/custom." + sid + "." + qtype + ".query";
			var key = sid + qtype;
			if (originals[key] == value) {
				// This works, but we still need the date field to get changes applied when it _has_ changed.
				return;
			}
			if (typeof(value) === "undefined") {
				return fs.remove(custom_fn);
			} else {
				return fs.write(custom_fn, value.trim().replace(/\r\n/g, '\n') + '\n');
			}
		}

		var sampledata = {
			deviceid: "1E1C2EF21CA1",
			ts: "2019-11-20T16:22:11",
			cabinet: "desk",
			label: "somebar6",
			phase: 3,
			gateid: "C4930003B679",
			point: 6,
			breakersize: 16
		};
		o = s.taboption("advanced", form.TextValue, "query_write_metadata", _("Query for metadata writing"),
			_("The parameterized sql query that will be used to insert metadata.  <code>$variable</code> can be used, with variables as from the following snippet.<p><pre>"
			+ JSON.stringify(sampledata, null, '\t')
			+ "</pre>"
			+ "<p>Fields are as provided by the user in the Cabinet Editor, with <code>ts</code> provided as a current timestamp to track updates."
			));
		o.rows = 3;
		o.cfgvalue = function(section_id) {
			return load_q(section_id, "metadata");
		};
		o.write = o.remove = function(section_id, formvalue) {
			return save_q(section_id, "metadata", formvalue);
		};

		var sampledata = {"mean":0,"gateid":"C4930003B679","max":0,"ts_start":1574259720000,"pname":"1E1C2EF21CA1/current/5","ts_ends":"2019-11-20T14:23:00","min":0,"interval":60,"ts_end":1574259780000,"max_ts":1574259721019,"min_ts":1574259721019,"selected":0,"stddev":0,"n":29}
		o = s.taboption("advanced", form.TextValue, "query_write_data", _("Query for data writing"),
			_("The parameterized sql query that will be used to insert data.  <code>$variable</code> can be used, with variables as from the following snippet.<p><pre>"
			+ JSON.stringify(sampledata, null, '\t')
			+ "</pre>"
			+ "<p>The <code>selected</code> variable contains the <code>max</code> value for energy counter types, and the <code>mean</code> for other types. "
			+ "<code>ts_ends</code> contains <code>ts_end</code> formatted as a string, and truncated to whole seconds to make construction of SQL timestamps easier. "
			+ "For other types, see the descriptions of the interval data in the 3rd party integration guide."
			));
		o.rows = 3;
		o.cfgvalue = function(section_id) {
			return load_q(section_id, "data");
		};
		o.write = o.remove = function(section_id, formvalue) {
			return save_q(section_id, "data", formvalue);
		};

		o = s.taboption("advanced", form.Flag, "validate_schema", _("Validate schema"), _("Whether we should attempt to update tables and schemas when we start"));

		o = s.taboption("advanced", form.Value, "_lastchange", _("Last change"), _("This field is used internally to ensure changes are saved. Please ignore it"));
		o.cfgvalue = function(section_id) {
			return new Date().toISOString();
		};

		return m.render();
	}
});