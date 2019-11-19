
create table if not exists data (
	id int auto_increment primary key,
	pname varchar(300),
	ts_end timestamp,
	period int,
	val double precision not null
);
