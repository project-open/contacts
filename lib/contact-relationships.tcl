# packages/contacts/lib/contact-relationships.tcl
#
# Include for the relationships of a contact
#
# @author Malte Sussdorff (sussdorff@sussdorff.de)
# @creation-date 2005-06-21
# @arch-tag: 291a71c2-5442-4618-bb9f-13ff23d854b5
# @cvs-id $Id$

foreach required_param {party_id} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {package_id} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

if {[empty_string_p $package_id]} {
    set package_id [ad_conn package_id]
}

set contacts_default_group [contacts::default_group -package_id $package_id]

if {![exists_and_not_null sort_by_date_p]} {
    set sort_by_date_p 0
}

if {$sort_by_date_p} {
    set sort_order "creation_date desc"
} else {
    set sort_order upper(other_name)
}

multirow create rels relationship relation_url rel_id contact contact_url attribute value creation_date role

set groups_belonging_to [db_list get_party_groups { select group_id from group_distinct_member_map where member_id = :party_id  and group_id > 0}]
lappend groups_belonging_to [contacts::default_group]

db_foreach get_relationships {} {
    if {[group::party_member_p -party_id $other_party_id -group_id $contacts_default_group]} {
	set contact_url [contact::url -party_id $other_party_id]
	if {[organization::organization_p -party_id $other_party_id]} {
	    set other_object_type "organization"
	} else {
	    set other_object_type "person"
	} 
	if {[string eq $rel_type "contact_rels_employment"]} {
	    set relation_url [export_vars -base "[ad_conn package_url]add/$other_object_type" -url {{group_ids $groups_belonging_to} {object_id_two "$party_id"} rel_type}]    
	} else {
	    set relation_url ""
	}
	
	set creation_date [lc_time_fmt $creation_date %q]
	set role_singular [lang::util::localize $role_singular]
	set other_name [contact::name -party_id $other_party_id -reverse_order]
	multirow append rels $role_singular $relation_url $rel_id $other_name $contact_url {} {} $creation_date $role
	
	# NOT YET IMPLEMENTED - Checking to see if role_singular or role_plural is needed
	
	if { [ams::list::exists_p -package_key "contacts" -object_type ${rel_type} -list_name ${package_id}] } {
	    set details_list [ams::values -package_key "contacts" -object_type $rel_type -list_name $package_id -object_id $rel_id -format "text"]
	    
	    if { [llength $details_list] > 0 } {
		foreach {section attribute_name pretty_name value} $details_list {
		    multirow append rels $role_singular $relation_url $rel_id $other_name $contact_url $pretty_name $value $creation_date $role
		}
	    }
	}
    }
}


template::multirow sort rels role contact