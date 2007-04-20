-- 
-- packages/contacts/sql/postgresql/upgrade/upgrade-1.2b3-1.2b4.sql
-- 
-- @author Matthew Geddert (openacs@geddert.com)
-- @creation-date 2006-02-13
-- @arch-tag: 
-- @cvs-id $Id$
--

-- contacts is no longer singleton. this cannot be updated via the info file
update apm_package_types set singleton_p = FALSE where package_key = 'contacts';

-- since contacts was singleton we know there is only one package_id we need to use
-- in migrating all our user data to the appropriate package

create function inline_0() returns integer as '
declare 
        v_package_id    integer;
begin
	v_package_id := package_id from apm_packages where package_key = ''contacts'';

        update acs_objects
           set title = ( select cs.title from contact_searches cs where cs.search_id = acs_objects.object_id ),
               package_id = v_package_id
         where object_id in ( select c.search_id from contact_searches c );

        update acs_objects
           set package_id = v_package_id
         where object_id in ( select item_id from contact_message_items );

        return 0;

end;' language 'plpgsql';

-- Calling and droping the function
select inline_0();
drop function inline_0();

drop view contact_messages;
create view contact_messages as 
    select cmi.item_id, 
           cmi.owner_id,
           cmi.message_type,
	   cmi.locale,
           cmi.banner,
           cmi.ps,
           cr.title,
           cr.description,
           cr.content,
           cr.mime_type as content_format,
           ao.package_id
      from contact_message_items cmi, cr_items ci, cr_revisions cr, acs_objects ao
     where cmi.item_id = cr.item_id
       and ci.publish_status not in ( 'expired' )
       and ci.live_revision = cr.revision_id
       and ci.item_id = ao.object_id
;

select define_function_args ('contact_search__new', 'search_id,title,owner_id,all_or_any,object_type,deleted_p;f,creation_date,creation_user,creation_ip,context_id,package_id');

drop function contact_search__new (integer,varchar,integer,varchar,varchar,boolean,timestamptz,integer,varchar,integer);
create or replace function contact_search__new (integer,varchar,integer,varchar,varchar,boolean,timestamptz,integer,varchar,integer,integer)
returns integer as '
declare
    p_search_id                     alias for $1;
    p_title                         alias for $2;
    p_owner_id                      alias for $3;
    p_all_or_any                    alias for $4;
    p_object_type                   alias for $5;
    p_deleted_p                     alias for $6;
    p_creation_date                 alias for $7;
    p_creation_user                 alias for $8;
    p_creation_ip                   alias for $9;
    p_context_id                    alias for $10;
    p_package_id                    alias for $11;
    v_search_id                     contact_searches.search_id%TYPE;
begin
    v_search_id := acs_object__new(
        p_search_id,
        ''contact_search'',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        coalesce(p_context_id, p_owner_id),
        ''1'',
        p_title,
        p_package_id
    );

    insert into contact_searches
    (search_id,owner_id,all_or_any,object_type,deleted_p)
    values
    (v_search_id,p_owner_id,p_all_or_any,p_object_type,p_deleted_p);

    return v_search_id;

end;' language 'plpgsql';
