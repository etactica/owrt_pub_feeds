create table if not exists sources (
	id int generated by default as identity primary key,
	pname varchar(300),
	breakersize integer,
	cabinetname varchar(1000),
	phase integer,
	label varchar(1000),
	gateway varchar(300)
);

create table if not exists data (
	id int generated by default as identity primary key,
	ts_end timestamp,
	period int,
	sourceid integer not null,
	val double precision not null,
	foreign key(sourceid) references sources(id)
);

create table if not exists metadata (
	mkey varchar(300) unique primary key,
	val varchar(1000) not null
);