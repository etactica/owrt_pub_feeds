create table if not exists sources (
	id int auto_increment primary key,
	deviceid varchar(300),
	pointid integer,
	breakersize integer,
	phase integer,
	cabinetname varchar(1000),
	label varchar(1000),
	gatewayid varchar(300),
	updated_at timestamp
);
