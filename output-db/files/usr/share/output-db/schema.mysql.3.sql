
create table if not exists metadata (
	mkey varchar(300) unique primary key,
	val varchar(1000) not null
);