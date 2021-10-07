## output-db
This service listens to the eTactica interval data stream and inserts the 
data into a configured SQL server.

## Features
* Multi-instance.  Send the same or different data to different databases.
* Select which datatypes to include/exclude
* Select intervals to include
* Schemas can be edited
* Schemas can be created if needed
* All queries can be templated and modified at will.
* Stats on operation can be sent to a StatsD server

## Limitations
Only supports postgres and mysql/mariadb at present.
TLS is only supported in postgres connections if the libpq driver was built with
TLS support, which is unfortunately not the default upstream.
TLS is not supported in mysql/mariadb connections due to a limitation in
how connection strings are handled in the luasql layer.

## Testing
If you want to test this service, some easy options are to use docker/podman
and also Amazon RDS.

### Testing postgres with docker/podman
This is just one way.  You use the username and database from below. The port
I’ve set as 32773 here, so it doesn’t clash with any other postgres
instance.  You cannot use -P as that will assign a new port even after
a stop/start cycle, so nothing can reconnect.
```
podman run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_USER=mydatastore -p 0.0.0.0:32773:5432 -d postgres:10-alpine
```


### Testing mysql with docker/podman
This is just one way.  You then use “root” as the username in the
gateway UI, the password chosen below, and the database name as chosen below.
```
podman run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -e MYSQL_DATABASE=yourdbname  -p 0.0.0.0:3306:3306 -d mysql:5
```

### Testing with Amazon RDS
Just make a "normal" RDS setup of either postgres or mysql/mariadb. Remember to
make sure that your database is public accessible, and that you have setup
whatever network access rules you desire to make sure that your gateways
can reach the RDS instance.  (Amazon Aurora has _not_ been tested at this stage,
regardless of compatibility settings)