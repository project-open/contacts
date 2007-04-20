-- Author Miguel Marin (miguelmarin@viaro.net)
-- Author Viaro Networks www.viaro.net
-- Creates a table to map contact_extend_options(extend_id)'s to 
-- contact_searches(search_id)

create table contact_search_extend_map (
	search_id	integer
			constraint contact_search_extend_map_search_id_fk
			references contact_searches (search_id)
			on delete cascade,
	extend_id	integer
			constraint contact_search_extend_map_extend_id_fk
			references contact_extend_options (extend_id)
			on delete cascade,
			constraint contact_search_extend_map_pk
			primary key (search_id,extend_id)
);