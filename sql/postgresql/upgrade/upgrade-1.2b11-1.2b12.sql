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
