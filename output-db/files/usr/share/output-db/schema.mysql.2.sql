
create table if not exists data (
	id int auto_increment primary key,
	ts_end timestamp,
	period int,
	sourceid integer not null,
	val double precision not null,
	foreign key(sourceid) references sources(id)
);
