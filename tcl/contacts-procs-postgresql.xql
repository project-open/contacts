<?xml version="1.0"?>
<queryset>

<fullquery name="contacts::default_group_not_cached.get_parent_subsite_id">
  <querytext>
    select object_id
      from site_nodes
     where tree_level(tree_sortkey) < ( select tree_level(n2.tree_sortkey) from site_nodes n2 where n2.node_id = :node_id )
       and object_id in ( select package_id
                            from apm_packages
                           where package_key = 'acs-subsite' )
     order by tree_sortkey desc
     limit 1
  </querytext>
</fullquery>

<fullquery name="contacts::default_groups_not_cached.get_child_contacts_instances">
  <querytext>
    select p.package_id
      from site_nodes n, site_nodes n2, apm_packages p
     where n2.node_id = (select coalesce(:parent_node_id, site_node__node_id('/', null)))
       and n.tree_sortkey between n2.tree_sortkey and tree_right(n2.tree_sortkey)
       and n.object_id = p.package_id
       and p.package_key = 'contacts'
       and (tree_level(n.tree_sortkey) - (select tree_level(n2.tree_sortkey) from site_nodes n2 where n2.node_id = (select coalesce(:parent_node_id, site_node__node_id('/', null))))) > 1;
  </querytext>
</fullquery>

<fullquery name="contacts::sweeper.get_persons_without_items">
  <querytext>
    select person_id
      from persons
     where person_id not in ( select item_id from cr_items ) 
     and person_id > 0
 </querytext>
</fullquery>

<fullquery name="contacts::sweeper.get_organizations_without_items">
  <querytext>
    select organization_id
      from organizations
     where organization_id not in ( select item_id from cr_items )
  </querytext>
</fullquery>

<fullquery name="contacts::sweeper.insert_privacy_records">
  <querytext>
    insert into contact_privacy
           ( party_id, email_p, mail_p, phone_p, gone_p )
    select party_id, 't'::boolean, 't'::boolean, 't'::boolean, 'f'::boolean
      from parties
     where party_id not in ( select party_id from contact_privacy )
  </querytext>
</fullquery>

<fullquery name="contacts::spouse_sync_attribute_ids.get_valid_attribute_ids">
  <querytext>
    select attribute_id
      from ams_attributes
     where object_type in ( 'party', 'person' )
       and attribute_id in ([template::util::tcl_to_sql_list $attribute_ids])
       and widget is not null
  </querytext>
</fullquery>

<fullquery name="contacts::spouse_rel_type_enabled_p.rel_type_enabled_p">
  <querytext>
    select 1
      from acs_rel_types
     where rel_type = 'contact_rels_spouse'
  </querytext>
</fullquery>

<fullquery name="contact::privacy_allows_p.is_type_allowed_p">
  <querytext>
    select ${type}_p
      from contact_privacy
     where party_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::privacy_set.record_exists_p">
  <querytext>
    select 1
      from contact_privacy
     where party_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::privacy_set.update_privacy">
  <querytext>
    update contact_privacy
       set email_p = :email_p,
           mail_p = :mail_p,
           phone_p = :phone_p,
           gone_p = :gone_p
     where party_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::privacy_set.insert_privacy">
  <querytext>
    insert into contact_privacy
           ( party_id, email_p, mail_p, phone_p, gone_p )
           values
           ( :party_id, :email_p, :mail_p, :phone_p, :gone_p )
  </querytext>
</fullquery>

<fullquery name="contact::util::generate_filename.get_parties_existing_filenames">
  <querytext>
    select name
      from cr_items
     where parent_id = :party_id
  </querytext>
</fullquery>

<fullquery name="contact::visible_p_not_cached.get_contact_visible_p">
  <querytext>
    select 1
      from group_approved_member_map
     where member_id = :party_id
       and group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
     limit 1
  </querytext>
</fullquery>

<fullquery name="contact::spouse_id_not_cached.get_spouse_id">
    <querytext>
        select CASE WHEN object_id_one = :party_id THEN object_id_two ELSE object_id_one END
          from acs_rels,
               acs_objects
         where rel_type = 'contact_rels_spouse'
           and ( object_id_one = :party_id or object_id_two = :party_id )
           and rel_id = object_id
         order by creation_date
    </querytext>
</fullquery>

<fullquery name="contact::spouse_id_not_cached.delete_rel">
    <querytext>
        select acs_object__delete(rel_id)
          from acs_rels
         where (
                 ( object_id_one = :party_id and object_id_two = :spouse )
               or
                 ( object_id_one = :spouse and object_id_two = :party_id )
               )
           and rel_type = 'contact_rels_spouse'
      </querytext>
</fullquery>

<fullquery name="contact::groups_list_not_cached.get_groups">
  <querytext>
    select groups.group_id,
           acs_objects.title as group_name,
           ( select count(distinct gamm.member_id) from group_approved_member_map gamm where gamm.group_id = groups.group_id ) as member_count,
           ( select count(distinct gcm.component_id) from group_component_map gcm where gcm.group_id = groups.group_id) as component_count,
           CASE WHEN contact_groups.package_id is not null THEN '1' ELSE '0' END as mapped_p,
           CASE WHEN default_p THEN '1' ELSE '0' END as default_p,
           CASE WHEN user_change_p THEN '1' ELSE '0' END as user_change_p
      from groups left join ( select * from contact_groups where package_id = :package_id ) as contact_groups on ( groups.group_id = contact_groups.group_id ), acs_objects
     where groups.group_id not in ('-1','[contacts::default_group -package_id $package_id]')
	and groups.group_id = acs_objects.object_id
       and groups.group_id not in ( select gcm.component_id from group_component_map gcm where gcm.group_id != -1 )
       and groups.group_id not in ( select group_id from application_groups )
       $filter_clause
     order by mapped_p desc, CASE WHEN contact_groups.default_p THEN '000000000' ELSE upper(groups.group_name) END
  </querytext>
</fullquery>

<fullquery name="contact::groups.get_components">
  <querytext>
            select groups.group_id,
                   groups.group_name,
                   ( select count(distinct gamm.member_id) from group_approved_member_map gamm where gamm.group_id = groups.group_id ) as member_count,
                   CASE WHEN package_id is not null THEN '1' ELSE '0' END as mapped_p,
                   CASE WHEN default_p THEN '1' ELSE '0' END as default_p
              from groups left join contact_groups on ( groups.group_id = contact_groups.group_id ), group_component_map
             where group_component_map.group_id = :group_id
               and group_component_map.component_id = groups.group_id
             order by upper(groups.group_name)
  </querytext>
</fullquery>

<fullquery name="contact::group::parent.get_parent">
  <querytext>
            select group_id
              from group_component_map
             where component_id = :group_id
               and group_id != '-1'
  </querytext>
</fullquery>

<fullquery name="contact::group::new.create_group">
  <querytext>
	select acs_group__new (
                :group_id,
                'group',
                now(),
                :creation_user,
                :creation_ip,
                :email,
                :url,
                :group_name,
                :join_policy,
                :context_id
        )
  </querytext>
</fullquery>

<fullquery name="contact::group::map.map_group">
  <querytext>
        insert into contact_groups
        (group_id,default_p,package_id)
        values
        (:group_id,:default_p,:package_id)
  </querytext>
</fullquery>

<fullquery name="contact::revision::new.insert_item">
  <querytext>
         insert into cr_items
         (item_id,parent_id,name,content_type)
         values
         (:party_id,contact__folder_id(),:party_id,'contact_party_revision');
     </querytext>
</fullquery>

</queryset>
