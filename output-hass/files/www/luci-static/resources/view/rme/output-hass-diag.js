'use strict';
'require fs';
'require ui';

// FIXME - we want an mq bridge, per instance, and a process, per instance, as configs may be different...

//return L.view.extend({
//	render: function() {
//		var m, s, o;

        // we only really care about the return code...
		var cmd = 'pidof output-hass.lua 2>&1 > /dev/null && echo "true"'

		fs.exec(cmd, [ 'blah' ]).then(function(res) {
            var myjs = {
                "friendly_name": "Output Home Assistant data integration",
                "expect_bridge": true,
                "expect_process": true,
                "process": res
            };
            return myjs;
		});
//	}
//});