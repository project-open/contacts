-- check to see if contact_complaint_tracking exists, if it does then we remove the contact_complaint_tracking_supplier_fk constriant

create function inline_0() returns integer as '
declare 
	v_table_count   boolean;
begin
	v_table_count := ''1'' from pg_constraint where conname = ''contact_complaint_tracking'';

        if v_table_count is true then 
            ALTER TABLE contact_complaint_tracking DROP CONSTRAINT contact_complaint_tracking_supplier_fk;
        end if;

     return 0;

end;' language 'plpgsql';

-- Calling and droping the function
select inline_0();
drop function inline_0();

