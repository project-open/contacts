-- contacts-package-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2004-07-28
-- @cvs-id $Id$
--
--


select define_function_args('contact_party_revision__new', 'party_id,party_revision_id,creation_date;now(),creation_user,creation_ip');


create or replace function contact_party_revision__new (
        integer,                -- party_id
        integer,                -- party_revision_id
        timestamptz,            -- creation_date
        integer,                -- creation_user
        varchar                 -- creation_ip
) returns integer
as '
declare
        p_party_id              alias for $1;
        p_party_revision_id     alias for $2;
        p_creation_date         alias for $3;
        p_creation_user         alias for $4;
        p_creation_ip           alias for $5;
        v_party_revision_id     cr_revisions.revision_id%TYPE;
        v_party_id              cr_items.item_id%TYPE;
begin

        v_party_id := contact_party_revision__item_id (
                p_party_id,
                p_creation_date,
                p_creation_user,
                p_creation_ip
        );

        v_party_revision_id := content_revision__new (
                NULL,                   -- title
                NULL,                   -- description
                now(),                  -- publish_date
                NULL,                   -- mime_type
                NULL,                   -- nls_language
                NULL,                   -- data
                v_party_id,             -- item_id
                p_party_revision_id,    -- revision_id
                p_creation_date,        -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip           -- creation_ip
        );

        PERFORM content_item__set_live_revision (v_party_revision_id);

        insert into contact_party_revisions ( party_revision_id ) values ( v_party_revision_id );

        return v_party_revision_id;
end;' language 'plpgsql';


create or replace function contact_party_revision__item_id (
        integer,                -- party_id
        timestamptz,            -- creation_date
        integer,                -- creation_user
        varchar                 -- creation_ip
) returns integer
as '
declare
        p_party_id              alias for $1;
        p_creation_date         alias for $2;
        p_creation_user         alias for $3;
        p_creation_ip           alias for $4;
        v_exists_p              boolean;
begin

        v_exists_p := ''1'' from cr_items where item_id = p_party_id;

        if v_exists_p is not true then
                insert into cr_items
                (item_id,parent_id,name,content_type)
                values
                (p_party_id,contact__folder_id(),p_party_id::varchar,''contact_party_revision'');
        end if;

        return p_party_id;
end;' language 'plpgsql';

create or replace function contact_party_revision__name (
        integer                 -- revision_id
) returns varchar 
as '
declare
        p_revision_id           alias for $1;
        v_first_names           varchar;
        v_last_name             varchar;
        v_organization          varchar;
        v_name                  varchar;
begin

        v_name := contact__name(item_id) || '' revision '' || to_char(revision_id,''FM9999999999999999999'') from cr_revisions where item_id = p_revision_id;
        return v_name;
end;' language 'plpgsql';

create or replace function contact__folder_id () returns integer
as '
declare
        v_folder_id              integer;
begin

        v_folder_id := cf.folder_id from cr_items ci, cr_folders cf
                            where ci.item_id = cf.folder_id
                              and ci.parent_id = ''-4''
                              and ci.name = ''contacts'';

        if v_folder_id is null then
                v_folder_id := content_folder__new (
                                  ''contacts'',
                                  ''Contacts'',
                                  NULL,
                                  ''-4''
                );
        end if;

        return v_folder_id;
end;' language 'plpgsql';

select content_folder__register_content_type(contact__folder_id(),'content_revision','t');

create or replace function contact__name (
        varchar,                -- first_names
        varchar,                -- last_name
        varchar,                -- organization
        boolean                 -- recursive_p
) returns varchar 
as '
declare
        p_first_names           alias for $1;
        p_last_name             alias for $2;
        p_organization          alias for $3;
        p_recursive_p           alias for $4;
        v_name                  varchar;
begin

        if p_recursive_p then
           if p_first_names is null and p_last_name is null then
              v_name := p_organization;
           else
              v_name := p_last_name;
              if p_first_names is not null and p_last_name is not null then
                 v_name := v_name || '', '';
              end if;
              v_name := v_name || p_first_names;
          end if;
        else 
           if p_first_names is null and p_last_name is null then
              v_name := p_organization;
           else
              v_name := p_first_names;
              if p_first_names is not null and p_last_name is not null then
                 v_name := v_name || '' '';
              end if;
              v_name := v_name || p_last_name;
          end if;
        end if;

        return v_name;
end;' language 'plpgsql';

create or replace function contact__name (
        integer                 -- party_id
) returns varchar 
as '
declare
        p_party_id              alias for $1;
        v_name                  varchar;
begin
        v_name := contact__name(p_party_id,''f'');

        return v_name;
end;' language 'plpgsql';

create or replace function contact__name (
        integer,                -- party_id
        boolean                 -- recursive_p  
) returns varchar 
as '
declare
        p_party_id              alias for $1;
        p_recursive_p           alias for $2;
        v_name                  varchar;
begin

        select name
          into v_name
          from organizations where organization_id = p_party_id;

        if v_name is null then

        if p_recursive_p = ''t'' then
          select last_name || '', '' || first_names
          into v_name
          from persons where person_id = p_party_id;
        else 
          select first_names || '' '' || last_name
          into v_name
          from persons where person_id = p_party_id;
        end if;

        end if;
        return v_name;
end;' language 'plpgsql';

create or replace function contact_group__member_count (
        integer                 -- group_id
) returns integer 
as '
declare
        p_group_id              alias for $1;
        v_member_count          integer;
begin
        v_member_count := count(*) from group_distinct_member_map where group_id = p_group_id ;

        return v_member_count;
end;' language 'plpgsql';


create or replace function contact_group__member_p (integer,integer) returns boolean 
as '
declare
        p_group_id              alias for $1;
        p_member_id             alias for $2;
        v_member_p              boolean;
begin

        v_member_p := ''1'' from group_distinct_member_map where group_id = p_group_id and member_id = p_member_id;

        if v_member_p is true then
           v_member_p := ''1'';
        else
           v_member_p := ''0'';
        end if;

        return v_member_p;
end;' language 'plpgsql';


-- create functions for organization_rels
select define_function_args('organization_rel__new','rel_id,rel_type;organization_rel,object_id_one,object_id_two,creation_user,creation_ip');

create or replace function organization_rel__new (integer,varchar,integer,integer,integer,varchar)
returns integer as '
declare
  new__rel_id            alias for $1;  -- default null  
  rel_type               alias for $2;  -- default ''organization_rel''
  object_id_one          alias for $3;  
  object_id_two          alias for $4;  
  creation_user          alias for $5;  -- default null
  creation_ip            alias for $6;  -- default null
  v_rel_id               integer;       
begin
    v_rel_id := acs_rel__new (
      new__rel_id,
      rel_type,
      object_id_one,
      object_id_two,
      object_id_one,
      creation_user,
      creation_ip
    );

    return v_rel_id;
   
end;' language 'plpgsql';

-- function new
create or replace function organization_rel__new (integer,integer)
returns integer as '
declare
  object_id_one          alias for $1;  
  object_id_two          alias for $2;  
begin
        return organization_rel__new(null,
                                    ''organization_rel'',
                                    object_id_one,
                                    object_id_two,
                                    null,
                                    null);
end;' language 'plpgsql';

-- procedure delete
create or replace function organization_rel__delete (integer)
returns integer as '
declare
  rel_id                 alias for $1;  
begin
    PERFORM acs_rel__delete(rel_id);

    return 0; 
end;' language 'plpgsql';
