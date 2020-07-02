'use strict';
'require form';
'require fs';
'require uci';

var desc = _(""
	+ "<p/>eTactica devices have remote cloud access built in, out of the box.  This allows you to access your "
	+ "device from anywhere in the world. This can be disabled if you prefer to manage your devices locally, but "
	+ "do note that you may then have to physically visit the device for any diagnostics. "
	+ "The values pre-configured here are unique for this device, and should not be changed or shared unless directed. "
	+ "<p/><a href='https://www.myetactica.com'>Get more information on the solution</a>"
);

var TrimmedValue = form.Value.extend({
	write: function(sid, formvalue) {
		this.super("write", [sid, formvalue.trim()]);
	}
})

var uciToBool = function(v, defval) {
	switch(String(v).toUpperCase()) {
	case '0':
	case 'N':
	case 'NO':
	case 'DISABLED':
	case 'FALSE':
		return false;
	case '1':
	case 'Y':
	case 'YES':
	case 'ENABLED':
	case 'TRUE':
		return true;
	default:
		return defval;
	}
}

function updateStatusNotRunning(rawmsg) {
	// Update status in DOM here...
	var status = document.getElementById('status-human');
	var raw = document.getElementById('status-raw');
	if (status && raw) {
		status.textContent = _("Not running: Do you have an internet connection? Do you have the correct credentials?") + blob.human;
		raw.textContent = rawmsg;

		var f = document.getElementById('pkversion');
		f.textContent = _("N/A");
		f = document.getElementById('pkpid');
		f.textContent = _("N/A");
		f = document.getElementById('pklastupdate');
		f.textContent = _("N/A");
	} else {
		// service is disabled, just ignore it.
	}
}

function updateStatusRunning(info) {
	var status = document.getElementById('status-raw');
	if (status && info) {
		status.textContent = (info.pagekitec_status + " (" + info.pagekitec_status_code + ")" || 'unknown');
		var human = document.getElementById('status-human');
		switch (info.pagekitec_status_code) {
		case 0: /* init */
		case 10: /* startup */
		case 20: /* connecting */
		case 30: /* updating DNS */
			human.textContent = _("Preparing service...");
			break;
		case 40: /* flying */
			human.textContent = _('Everything appears normal');
			break;
		case 50: /* problems */
			human.textContent= _("Something isn't working. Check your access credentials or the logs for hints");
			break;
		case 90: /* no_network */
			human.textContent = _('Check your network connection, and/or the access credentials');
			break;
		default:
			break;
		}
	}
	var f;
	f = document.getElementById('pkversion');
	if (f && info) {
		f.textContent = info.pagekitec_version;
	}
	f = document.getElementById('pkpid');
	if (f && info) {
		f.textContent = info.pagekitec_pid;
	}
	f = document.getElementById('pklastupdate');
	if (f && info) {
		f.textContent = (new Date() - new Date(info.pagekitec_update_ts * 1000)) / 1000 + " seconds ago";
	}

}


return L.view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(fs.read_direct('/tmp/remake.d/et-remote.status.json')),
			uci.load('et-remote')
		]);
	},

	render: function(blob) {
		var m, s, o;
		var enabled = uciToBool(uci.get("et-remote", "options", "enabled"));
		var kname = uci.get("et-remote", "options", "kitename");

		m = new form.Map('et-remote', _('eTactica Remote Access'), desc);

		s = m.section(form.NamedSection, 'global');
		s.render = L.bind(function(view, section_id) {
			if (enabled) {
				var status = blob.pagekitec_status ? blob.pagekitec_status : _('Loading...');
				var age = _('Loading...');
				if (blob.pagekitec_update_ts) {
					age = (new Date() - new Date(blob.pagekitec_update_ts * 1000)) / 1000 + " seconds ago";
				}
				return E('div', { 'class': 'cbi-section' }, [
					E('h3', _('Information')),

					E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
					E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Your remote access URL')),
					E('div', { 'class': 'cbi-value-field', 'id': 'raurl', 'style': 'font-weight: bold;margin-bottom:5px;color:#37c' },
					  E('a', {'href': 'https://' + kname + '.myetactica.com'}, 'https://' + kname + '.myetactica.com'),
					  )]),

					E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
					E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Status')),
					E('div', { 'class': 'cbi-value-field', 'style': 'margin-bottom:5px;color:#37c' }, [
						E('p', {'id': 'status-human'}, _("Loading...")),
						E('p', {'id': 'status-raw'}, status)
						])
					]),

					E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
					E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Remote Access SW Version')),
					E('div', { 'class': 'cbi-value-field', 'id': 'pkversion', 'style': 'margin-bottom:5px;color:#37c' }, blob.pagekitec_version)]),

					E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
					E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('PK PID')),
					E('div', { 'class': 'cbi-value-field', 'id': 'pkpid', 'style': 'margin-bottom:5px;color:#37c' }, blob.pagekitec_pid)]),

					E('div', { 'class': 'cbi-value', 'style': 'margin-bottom:5px' }, [
					E('label', { 'class': 'cbi-value-title', 'style': 'padding-top:0rem' }, _('Last updated')),
					E('div', { 'class': 'cbi-value-field', 'id': 'pklastupdate', 'style': 'margin-bottom:5px;color:#37c' }, age)]),
				]);
			} else {
				return E('div', { 'class': 'cbi-section' }, [
					E('h3', _('Information')),
					E('p', _('The remote-access solution is disabled.  This is normal if you have disabled it yourself'
					 + ' or your gateway has upgraded from an older version.  Contact support if you wish to enable the'
					 + ' remote-access solution.')),
				]);
            }

		}, o, this);


		pollData: L.Poll.add(function() {
			return fs.read_direct('/tmp/remake.d/et-remote.status.json').then(function(res) {
				var info = JSON.parse(res);
				// Unfortunately, we kinda have to repeat the same checks as the LED monitor
				if (info) {
					var proc = fs.read_direct("/proc/" + info.pagekitec_pid + "/cmdline").then(function(res) {
						if (res.indexOf("pagekitec") >= 0) {
							updateStatusRunning(info);
						} else {
							updateStatusNotRunning("PID doesn't appear to be correct service");
						}

					}, function(failedres) {
						updateStatusNotRunning("No process with PID from state file");
					});
				} else {
					updateStatusNotRunning("Status file is invalid");
				}
			}, function(nostatusfile) {
				updateStatusNotRunning("No status file found");
			});
		}, 3);

		this.pollData;


		s = m.section(form.TypedSection, 'options', _("Configuration"));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, "enabled", _("Enable Remote Access"), _("Disable this service only if you have local network access"));

		// TODO - make these both required iff it's enabled?
		o = s.option(TrimmedValue, "kitename", _("Service Name"), _("This is normally preconfigured in manufacturing"));
		o = s.option(TrimmedValue, "kitesecret", _("Service Secret"), _("This is normally preconfigured in manufacturing"));
		o.password = true;

		return m.render();
	}
});
