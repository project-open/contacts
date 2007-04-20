-- author Miguel Marin (miguelmarin@viaro.net)
-- author Viaro Networks www.viaro.net
-- Making all entries in contact_message_log an acs_object

-- Creating the acs_object_type for contact_message_logs

select acs_object_type__create_type (
   'contact_message_log',         -- content_type
   'Contacts Message Log',        -- pretty_name 
   'Contacts Messages Logs',      -- pretty_plural
   'acs_object',                  -- supertype
   'contact_message_log',         -- table_name
   'object_id',                   -- id_column 
   'contact_messages_log',        -- package_name
   'f',                           -- abstract_p
   NULL,                          -- type_extension_table
   NULL                           -- name_method
);


-- Making every message_id in contact_message_log an acs_objects

create function inline_0() returns integer as '
declare 
	v_row         record;
	v_object_id   integer;
begin

     for v_row in select * from contact_message_log
     loop
	-- Since all entries in this table where created using acs_objects_seq.nextval
	-- we just need to create an acs_object for that meessage_id
        v_object_id := acs_object__new(
			     v_row.message_id,
			     ''contact_message_log'',
			     v_row.sent_date,
			     v_row.sender_id,
			     null,
			     null
	);
     end loop;
     return 0;

end;' language 'plpgsql';

-- Calling and droping the function
select inline_0();
drop function inline_0();


-- Altering the table so every new message_id reference acs_objects object_id
alter table contact_message_log 
add constraint contact_message_log_message_id_fk 
foreign key (message_id) references acs_objects (object_id);


