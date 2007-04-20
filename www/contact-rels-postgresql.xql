<?xml version="1.0"?>
<queryset>

<fullquery name="get_valid_object_types">
      <querytext>
select primary_object_type
  from contact_rel_types
 where primary_role = :role_two 
      </querytext>
</fullquery>

<fullquery name="get_rels">
      <querytext>
select acs_rel_type__role_pretty_name(primary_role) as pretty_name,
       primary_role as role
  from contact_rel_types
 where secondary_object_type in ( :contact_type, 'party' )
 group by primary_role
 order by upper(acs_rel_type__role_pretty_name(primary_role))
      </querytext>
</fullquery>

<fullquery name="get_relationships">
      <querytext>
select rel_id, other_name, other_party_id, role_singular, rel_type, object_id_one, object_id_two
from 
(
    select CASE WHEN object_id_one = :party_id THEN contact__name(object_id_two) ELSE contact__name(object_id_one) END as other_name,
           CASE WHEN object_id_one = :party_id THEN object_id_two ELSE object_id_one END as other_party_id,
           CASE WHEN object_id_one = :party_id THEN role_two ELSE role_one END as role,
           CASE WHEN object_id_one = :party_id THEN acs_rel_type__role_pretty_name(role_two) ELSE acs_rel_type__role_pretty_name(role_one) END as role_singular,
           CASE WHEN object_id_one = :party_id THEN acs_rel_type__role_pretty_plural(role_two) ELSE acs_rel_type__role_pretty_name(role_two) END as role_plural,
           role_one, role_two,
           acs_rels.rel_id, acs_rels.rel_type, object_id_one, object_id_two
      from acs_rels,
           acs_rel_types
     where acs_rels.rel_type = acs_rel_types.rel_type
       and ( object_id_one = :party_id or object_id_two = :party_id )
       and acs_rels.rel_type in ( select object_type from acs_object_types where supertype = 'contact_rel')
) rels_temp, group_distinct_member_map
    where rels_temp.other_party_id = group_distinct_member_map.member_id
      and group_distinct_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups]])
[template::list::orderby_clause -orderby -name "relationships"]
      </querytext>
</fullquery>

<fullquery name="contacts_select">      
      <querytext>
select contact__name(parties.party_id),
       parties.party_id,
       cr_revisions.revision_id,
       contact__name(parties.party_id,:name_order) as name,
       parties.email,
       ( select first_names from persons where person_id = party_id ) as first_names,
       ( select last_name from persons where person_id = party_id ) as last_name,
       ( select name from organizations where organization_id = party_id ) as organization
  from parties left join cr_items on (parties.party_id = cr_items.item_id) left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ) , group_distinct_member_map
 where parties.party_id = group_distinct_member_map.member_id
   and group_distinct_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups]])
 $type_clause
 [contact::search_clause -and -search_id $search_id -query $query -party_id "parties.party_id" -revision_id "revision_id"]
 order by upper(contact__name(parties.party_id))
 limit 100
      </querytext>
</fullquery>


</queryset>
