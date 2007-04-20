create table contact_complaint_tracking (
	complaint_id    integer
			constraint contact_complaint_tracking_pk 
			primary key
			constraint contact_complaint_tracking_fk
			references cr_revisions(revision_id)
			on delete cascade,
	customer_id 	integer
			constraint contact_complaint_tracking_user_id_fk
			references users(user_id) on delete cascade,
	turnover	float,
	percent		integer,
	supplier_id	integer,
	paid		float,
	object_id	integer,
	state 		varchar(10),
			constraint cct_state_ck
			check (state in ('valid','invalid','open'))
);