## output-thingsboard - Initial ThingsBoard integration.

Listens to the live data stream, and directly relays all live readings to thingsboard as telemetry.
The eTactica gateway appears as a single device, and all measured values from all Modbus devicess simply appear
as keyed telemetry values beneath this single device.


### Attribute handling:

The demo script listens for updates to shared attributes from the server.  These arrive on `ext/thingsboard/in/attributes`

To publish client attributes, publish a message to `ext/thingsboard/out/attributes`

### RPC handling:

The demo script listens for RPC requests from the server.  These arrive on `ext/thingsboard/in/rpc`
The existing script simply logs them, and replies with the correct request id and echos the input parameters.

Look for the section in the script marked `TODO insert your custom RPC handling here`