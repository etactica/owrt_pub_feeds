'use strict';
'require form';
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

		o = s.taboption("general", form.Value, "dbhost", _("Database hostname"), _("Hostname of your database server"))
		o.placeholder = "my-db-instance.some-zone.rds.amazonws.com"

		o = s.taboption("general", form.Value, "dbport", _("Database port"), _("Port your database server runs on. You can normally leave this blank"))
		o.placeholder = _("default")

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

		/* FIXME - need to get something here that can load/store to a file properly, like we do in rme-alert-emailer */
		o = s.taboption("advanced", form.TextValue, "query_write_metadata", _("Query for metadata writing"), _("The parameterized sql query that will be used to insert metadata"));
		o = s.taboption("advanced", form.TextValue, "query_write_data", _("Query for data writing"), _("The parameterized sql query that will be used to insert data"));

		o = s.taboption("advanced", form.Flag, "validate_schema", _("Validate schema"), _("Whether we should attempt to update tables and schemas when we start"));

		return m.render();
	}
});