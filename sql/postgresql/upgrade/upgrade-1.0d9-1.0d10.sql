-- Author Miguel Marin (miguelmarin@viaro.net)
-- Author Viaro Networks www.viaro.net
-- Create a sequence and a table for extended searches.

create sequence contact_extend_search_seq;

create table contact_extend_options (
	extend_id 	integer
			constraint contact_extend_options_pk primary key,
	var_name	varchar(100) unique not null,
	pretty_name	varchar(100) not null,
	subquery 	varchar(5000) not null,
	description     varchar(500)
);