ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:multiple,integer,notnull}
    {group_id:integer,notnull}
    {return_url ""}
}

set party_id [lindex $party_id 0]
contact::require_visiblity -party_id $party_id
set object_type [contact::type -party_id $party_id]
switch $object_type {
    person - user {
	set rel_type "membership_rel"
    }
    organization {
	set rel_type "organization_rel"
    }
    default {
	set rel_type "membership_rel"
    }
}
if {$rel_type == "organization_rel"} {
    set user_id [ad_conn user_id]
    set ip_addr [ad_conn peeraddr]
    set rel_id [db_exec_plsql add_organization_rel {}]
    db_dml insert_state {}
    
    # Execute the callback for the organization depending on the group they are added to.
    # We use this callback to add the organization to .LRN if it is a Customer
    callback contact::organization_new_group -organization_id $party_id -group_id $group_id
	
} else {
    set rel_id [relation::get_id -object_id_one $group_id -object_id_two $party_id -rel_type "membership_rel"]
    if { [exists_and_not_null rel_id] } {
	# this relationship was previously deleted and needs to be approved
	db_dml update_state {}
    } else {
	group::add_member \
	    -group_id $group_id \
	    -user_id $party_id \
	    -rel_type membership_rel

	callback contact::person_new_group -person_id $party_id -group_id $group_id
    }
}


if { ![exists_and_not_null return_url] } {
    set return_url[contact::url -party_id $party_id]
}
contact::search::flush_results_counts
ad_returnredirect $return_url
