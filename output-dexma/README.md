## output-dexma
Parses the eTactica _interval_ stream, and packages up Dexma HTTPS
insertion API messages.  You'll need a working Dexma account, and
the ability to create virtual gateways.

## Functions supported
* Selecting data points to send
* Selecting intervals to send
* Diagnostics of running service
* Credential testing
* Custom parameters can be configured by hand
* Stats on operation can be sent to a StatsD server

## Limitations
Only a single instance of the service is supported.  If you need to
post to multiple DEXCell accounts from the same eTactica Gateway,
please get in touch.

## Testing
Without a dexma account, the best you can do is setup a fake HTTPS endpoint,
for instance using [Hookbin](https://hookb.in) You can then edit
the ```/etc/config/output-dexma``` config file, and overwrite
the url_template, such as:
```
option url_template 'https://hookb.in/ABCDtokentextCAFE?source_key=%s'
```
