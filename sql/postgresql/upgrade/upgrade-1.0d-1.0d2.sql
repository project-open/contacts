-- contacts/sql/postgresql/upgrade/upgrade-1.0d-1.0d2.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2005-06-14
-- @cvs-id $Id$
--
--


alter table contact_searches add column deleted_p boolean;
alter table contact_searches alter deleted_p set default 'f';
update contact_searches set deleted_p = 'f';
alter table contact_searches alter deleted_p set not null;

create table contact_search_log (
        search_id               integer
                                constraint contact_search_log_search_id_fk references contact_searches(search_id) on delete cascade
                                constraint contact_search_logs_search_id_nn not null,
        user_id                 integer
                                constraint contact_search_log_user_id_fk references users(user_id) on delete cascade
                                constraint contact_search_log_user_id_nn not null,
        n_searches              integer
                                constraint contact_search_log_n_searches_nn not null,
        last_search             timestamptz
                                constraint contact_search_log_last_search_nn not null,
        unique(search_id,user_id)
);

select define_function_args ('contact_search__new', 'search_id,title,owner_id,all_or_any,object_type,deleted_p;f,creation_date,creation_user,creation_ip,context_id');
create or replace function contact_search__new (integer,varchar,integer,varchar,varchar,boolean,timestamptz,integer,varchar,integer)
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
    v_search_id                     contact_searches.search_id%TYPE;
begin
    v_search_id := acs_object__new(
        p_search_id,
        ''contact_search'',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        coalesce(p_context_id, p_owner_id)
    );

    insert into contact_searches
    (search_id,title,owner_id,all_or_any,object_type,deleted_p)
    values
    (v_search_id,p_title,p_owner_id,p_all_or_any,p_object_type,p_deleted_p);

    return v_search_id;

end;' language 'plpgsql';



create or replace function contact_search__log (integer,integer)
returns integer as '
declare
    p_search_id                     alias for $1;
    p_user_id                       alias for $2;
    v_last_search_id                integer;
    v_exists_p                      boolean;
begin
    -- if the user has used this search in the last 60 minutes we do not log it as a new search
    v_last_search_id := search_id
                   from contact_search_log
                  where user_id = p_user_id
                    and last_search > now() - ''1 hour''::interval
                  order by last_search desc
                  limit 1;

    if v_last_search_id != p_search_id or v_last_search_id is null then
       -- this is a new search we need to log
       v_exists_p := ''1''::boolean
                from contact_search_log 
               where search_id = p_search_id
                 and user_id = p_user_id;

       if v_exists_p then
         update contact_search_log
            set n_searches = n_searches + 1,
                last_search = now()
          where search_id = p_search_id
            and user_id = p_user_id;
       else
         insert into contact_search_log
         (search_id,user_id,n_searches,last_search)
         values
         (p_search_id,p_user_id,''1''::integer,now());
       end if;
    else
       -- we just update the last search time but no n_sesions
       update contact_search_log
          set last_search = now()
        where search_id = p_search_id
          and user_id = p_user_id;
    end if;

    return ''1'';
end;' language 'plpgsql';

