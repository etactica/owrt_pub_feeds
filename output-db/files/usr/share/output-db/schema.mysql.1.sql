create table if not exists sources (
	id int auto_increment primary key,
	pname varchar(300),
	breakersize integer,
	cabinetname varchar(1000),
	phase integer,
	label varchar(1000),
	gateway varchar(300)
);
