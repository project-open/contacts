ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:integer,multiple,optional}
    {party_ids:optional}
    {return_url "./"}
} -validate {
    valid_party_submission {
	if { ![exists_and_not_null party_id] && ![exists_and_not_null party_ids] } { 
	    ad_complain "[_ contacts.lt_Your_need_to_provide_]"
	}
    }
}
if { [exists_and_not_null party_id] } {
    set party_ids [list]
    foreach party_id $party_id {
	lappend party_ids $party_id
    }
}
foreach id $party_ids {
    contact::require_visiblity -party_id $id
}


set title "[_ contacts.Add_to_Group]"
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]
set context [list $title]
set package_id [ad_conn package_id]
set recipients [list]
foreach party_id $party_ids {
    lappend recipients "<a href=\"[contact::url -party_id $party_id]\">[contact::name -party_id $party_id]</a>"
}
set recipients [join $recipients ", "]

set form_elements {
    party_ids:text(hidden)
    return_url:text(hidden)
    {recipients:text(inform),optional {label "[_ contacts.Contacts]"}}
}

set group_options [contact::groups -expand "all" -privilege_required "create"]
if { [llength $group_options] == "0" } {
    ad_return_error "[_ contacts.lt_Insufficient_Permissi]" "[_ contacts.lt_You_do_not_have_permi]"
}

append form_elements {
    {group_ids:text(checkbox),multiple {label "[_ contacts.Add_to_Groups]"} {options $group_options}}
}
set edit_buttons [list [list "[_ contacts.lt_Add_to_Selected_Group]" create]]




ad_form -action group-parties-add \
    -name add_to_group \
    -cancel_label "[_ contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -on_submit {
	db_transaction {
            foreach group_id $group_ids {
                foreach party_id $party_ids {

                    switch [contact::type -party_id $party_id] {
                        person - user {
                            set rel_type "membership_rel"
                        }
                        organization {
			    # Execute the callback for the organization depending on the group they are added to.
			    # We use this callback to add the organization to .LRN if it is a Customer
			    callback contact::organization_new_group -organization_id $party_id -group_id $group_id
                            set rel_type "organization_rel"
                        }
                    }
		    
		    # relation-add does not work as there is no
		    # special procedure for organizations at
		    # the moment.
		    set existing_rel_id [db_string rel_exists { 
			select rel_id
			from   acs_rels 
			where  rel_type = :rel_type 
			and    object_id_one = :group_id
			and    object_id_two = :party_id
		    } -default {}]
		    
		    if { [empty_string_p $existing_rel_id] } {
			set rel_id [db_string insert_rels { select acs_rel__new (NULL::integer,:rel_type,:group_id,:party_id,NULL,:user_id,:peeraddr) as org_rel_id }]
			db_dml insert_state { insert into membership_rels (rel_id,member_state) values (:rel_id,'approved') }
		    } else {
			# we approve the existing rel which may not be approved
			db_dml update_state { update membership_rels set member_state = 'approved' where rel_id = :existing_rel_id }
		    }
		    
                }
            }
	}
    } -after_submit {
	contact::search::flush_results_counts
	ad_returnredirect $return_url
	ad_script_abort
    }


