ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$


} {
    {object_type "employee"}
    {group_ids ""}
    {rel_type ""}
    {role_two ""}
    {object_id_two ""}
} -validate {
    valid_type -requires {object_type} {
	if { [lsearch [list organization person employee] $object_type] < 0 } {
	    ad_complain "[_ contacts.lt_You_have_not_specifie]"
	}
    }
}
set master_src [parameter::get -parameter "ContactsMaster"]
set default_group [contacts::default_group]

set group_list [concat [list [list [_ contacts.All_Contacts] $default_group "0"]] [contact::groups]]

if {[empty_string_p $group_ids] && [llength $group_list] > 1} {
    ad_returnredirect "[export_vars -base "../select-groups" -url {object_type object_id_two role_two rel_type}]"
} elseif { ![string eq $group_ids ""] && [lsearch $group_ids $default_group] < 0 } {
    # an invalid group_ids list has been specified or they do not have permission to add person
    ad_return_error "[_ contacts.lt_Insufficient_Permissi]" "[_ contacts.lt_You_do_not_have_permi]"
} elseif { [string eq $group_ids ""]} {
    lappend group_ids $default_group
}


set path_info [ad_conn path_info]
if { $path_info eq "add/person" } {
    set object_type "person"
} elseif { $path_info eq "add/organization" } {
    set object_type "organization"
} elseif { $path_info eq "add/employee" } {
    set object_type "employee"
}

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]

set form_elements {party_id:key}
lappend form_elements {object_type:text(hidden)}
lappend form_elements {rel_type:text(hidden),optional}
lappend form_elements {object_id_two:text(hidden),optional}
# the following line added 2006/08/02 by cognovis/nfl 
lappend form_elements {role_two:text(hidden),optional}

if {[lsearch $group_ids $default_group] == -1} {
    lappend group_ids $default_group
}

lappend form_elements {group_ids:text(hidden)}

# Save Group Information
set group_list [contact::groups -expand "all" -privilege_required "read"]
set group_list [concat [list [list [_ contacts.All_Contacts] $default_group 0]] $group_list]


ad_form -name party_ae \
    -mode "edit" \
    -cancel_label "[_ contacts.Cancel]" \
    -cancel_url [ad_conn package_url] \
    -edit_buttons [list [list "[_ acs-kernel.common_Save]" save] ]\
    -form $form_elements

# List to get the elements to the form
set list_names [list]

foreach group $group_list {
    set group_id [lindex $group 1]
    if { [lsearch $group_ids $group_id] >= 0 } {
	
	# Adding the list_name to get the elements in the form
	lappend list_names [list ${package_id}__${group_id}]
	
	# Add the category widget(s)
	set element_name "category_ids$group_id"
	if {$group_id < 0} {
	    set element_name "category_ids[expr 0 - $group_id]"
	}
	
	category::ad_form::add_widgets \
	    -container_object_id $group_id \
	    -categorized_object_id $user_id \
	    -form_name party_ae \
	    -element_name $element_name
	
    }
}


if {$object_type eq "employee"} {
    
    # Make sure the relationship is set correctly
    set rel_type "contact_rels_employment"
    set role_two ""
    
    # Employee is like adding a business card. First company information, then person information
    set form_definition [ams::ad_form::elements \
			     -package_key "contacts" \
			     -object_types "[list person organization]" \
			     -list_names $list_names]

} else {
    set form_definition [ams::ad_form::elements \
			     -package_key "contacts" \
			     -object_type $object_type \
			     -list_names $list_names]
}

if { [parameter::get -boolean -package_id $package_id -parameter "ContactPrivacyEnabledP" -default "0"] } {
    set privacy_setting_options [list]
    if { $object_type eq "organization" } {
	lappend privacy_setting_options [list [_ contacts.This_organization_has_closed_down] gone_p]
    } else {
	lappend privacy_setting_options [list [_ contacts.This_person_is_deceased] gone_p]
    }
    lappend privacy_setting_options [list [_ contacts.Do_not_email] email_p]
    lappend privacy_setting_options [list [_ contacts.Do_not_mail] mail_p]
    lappend privacy_setting_options [list [_ contacts.Do_not_phone] phone_p]
    
    lappend form_definition [list contact_privacy_settings:boolean(checkbox),multiple,optional \
				 [list label [_ contacts.Privacy_Settings]] \
				 [list options $privacy_setting_options] \
				]
}



# Creating the form
ad_form -extend -name party_ae -form $form_definition

# Append relationship attributes

if {[exists_and_not_null role_two]} {
    set rel_type [db_string select_rel_type "select rel_type from contact_rel_types where secondary_object_type = :object_type and secondary_role = :role_two" -default ""]
    # the following line added 2006/08/02 by cognovis/nfl
    if {$rel_type == ""} {
	set rel_type [db_string select_rel_type "select rel_type from contact_rel_types where secondary_object_type = 'party' and secondary_role = :role_two" -default ""] 
    }
}

if {[exists_and_not_null rel_type]} {
    ad_form -extend -name party_ae -form [ams::ad_form::elements -package_key "contacts" -object_type $rel_type -list_name [ad_conn package_id]]
}


# Append the option to create a user who get's a welcome message send
# Furthermore set the title.

if { $object_type eq "person" } {
    set title "[_ contacts.Add_a_Person]"
} elseif { $object_type eq "organization"} {
    set title "[_ contacts.Add_an_Organization]"
} else { 
    set title "[_ contacts.Add_an_Employee]"
}

set context [list $title]

if {$object_type eq "employee"} {
    callback contact::contact_form -package_id $package_id -form party_ae -object_type "organization" -group_ids $group_ids -rel_type $rel_type
    callback contact::contact_form -package_id $package_id -form party_ae -object_type "person" -group_ids $group_ids -rel_type $rel_type
} else {
    callback contact::contact_form -package_id $package_id -form party_ae -object_type $object_type -group_ids $group_ids -rel_type $rel_type
}

ad_form -extend -name party_ae \
    -on_request {
	
	if { $object_type eq "person" }	{
	    set required_attributes [list first_names last_name email]
	} elseif {$object_type eq "organization"} {
	    set required_attributes [list name]
	} else {
	    set required_attributes [list first_names last_name email name]
	}
	set missing_elements [list]
	foreach attribute $required_attributes {
	    if { [string is false [template::element::exists party_ae $attribute]] } {
		lappend missing_elements $attribute
	    }
	}
	# make the error message multiple item aware
	if { [llength $missing_elements] > 0 } {
            ad_return_error "[_ contacts.Configuration_Error]" "[_ contacts.lt_Some_of_the_required_]<ul><li>[join $missing_elements "</li><li>"]</li></ul>"
	}
    } -new_request {
	foreach group $group_ids {
	    if { ![permission::permission_p -object_id $group -party_id $user_id -privilege "create"] } {
		ad_return_error "[_ contacts.lt_Insufficient_Permissi]" "[_ contacts.lt_You_do_not_have_permi]"
		ad_script_abort
	    }
	}
    } -edit_request {
	foreach group $group_ids {
	    if { ![permission::permission_p -object_id $group -party_id $user_id -privilege "write"] } {
		ad_return_error "[_ contacts.lt_Insufficient_Permissi]" "[_ contacts.lt_You_do_not_have_permi]"
		ad_script_abort
	    }
	}
    } -on_submit {
	
	# for orgs name needs to be unique
        # for users username needs to be unique
	# for all of them email needs to be unique
	
	if { $object_type == "person" } {
	    if { ![exists_and_not_null first_names] } {
		template::element::set_error party_ae first_names "[_ contacts.lt_First_Names_is_requir]"
	    }
	    if { ![exists_and_not_null last_name] } {
		template::element::set_error party_ae last_name "[_ contacts.lt_Last_Name_is_required]"
	    }
	} elseif {$object_type eq "organization"} {
	    if { ![exists_and_not_null name] } {
		template::element::set_error party_ae name "[_ contacts.Name_is_required]"
	    }
	} else {
	    if { ![exists_and_not_null name] } {
		template::element::set_error party_ae name "[_ contacts.Name_is_required]"
	    }
	    if { ![exists_and_not_null first_names] } {
		template::element::set_error party_ae first_names "[_ contacts.lt_First_Names_is_requir]"
	    }
	    if { ![exists_and_not_null last_name] } {
		template::element::set_error party_ae last_name "[_ contacts.lt_Last_Name_is_required]"
	    }
	}

	if { [exists_and_not_null email] } {
	    set other_party_id [party::get_by_email -email $email]
	    if { ![empty_string_p $other_party_id] } {
		set another_contact [contact::link -party_id $other_party_id]
                template::element::set_error party_ae email "[_ contacts.lt_-another_contact-_already_uses_this_email]"
            }
        }
	
	if { ![template::form::is_valid party_ae] } {
	    break
	}
	
    } -new_data {

	if {$object_type eq "employee"} {
	    set object_types [list person organization]
	    set person_party_id $party_id
	    set organization_party_id ""
	} else {
	    set object_types $object_type
	    set ${object_type}_party_id $party_id
	}
	set orig_object_type $object_type

	foreach object_type $object_types {
	    if { $object_type eq "person" } {
		
		if { ![exists_and_not_null url] } {
		    set url ""
		}
		
		# Initialize Person
		template::form create add_party
		template::element create add_party email -value "$email"
		template::element create add_party first_names -value "$first_names"
		template::element create add_party last_name -value "$last_name"
		template::element create add_party url -value "$url"
		set person_party_id [party::new -party_id $person_party_id -form_id add_party person]

		# party::new does not correctly save email address
		party::update -party_id $person_party_id -email $email -url $url
            
		# in order to create a user we need a valid unique username (i.e. their email address).
		# the on_submit block has already validated that this is in fact a valid and unique 
		# email address which will serve as their username
		callback contact::person_add -package_id $package_id -person_id $person_party_id
		
		# Add the new categories and enter the Party into the groups
		set cat_ids [list]
		
		foreach group_id $group_ids {
		    group::add_member \
			-group_id $group_id \
			-user_id $person_party_id \
			-rel_type "membership_rel"
		    
		    set element_name "category_ids$group_id"
		    if {$group_id < 0} {
			set element_name "category_ids[expr - $group_id]"
		    }
		    
		    set cat_ids [concat $cat_ids \
				     [category::ad_form::get_categories \
					  -container_object_id $group_id \
					  -element_name $element_name]]
		}
		
		category::map_object -remove_old -object_id $person_party_id $cat_ids
		callback contact::special_attributes::ad_form_save -party_id $person_party_id -form "party_ae"
	    } else {
		
		# Initialize Party Entry for organization
		set organization_party_id [organization::new -organization_id $organization_party_id -name $name]
		
		foreach group_id $group_ids {
		    if {![empty_string_p $group_id]} {
			
			# relation-add does not work as there is no
			# special procedure for organizations at the moment.
			set rel_id [db_string insert_rels { select acs_rel__new (NULL::integer,'organization_rel',:group_id,:organization_party_id,NULL,:user_id,:peeraddr) as org_rel_id }]
			db_dml insert_state { insert into membership_rels (rel_id,member_state) values (:rel_id,'approved') }
		    }
		}
		
		callback contact::special_attributes::ad_form_save -party_id $organization_party_id -form "party_ae"
		callback contact::organization_new -package_id $package_id -contact_id $organization_party_id -name $name
	    }
	
	    # Save the contact information
	    # No clue why this is not part of the db_transaction though ....

	    set revision_id [contact::revision::new -party_id [set ${object_type}_party_id]]
	    foreach group_id $group_ids {
		ams::ad_form::save -package_key "contacts" \
		    -object_type $object_type \
		    -list_name "${package_id}__${group_id}" \
		    -form_name "party_ae" \
		    -object_id $revision_id
		
		callback contact::${object_type}_new_group -${object_type}_id [set ${object_type}_party_id] -group_id $group_id

		# execute group specific callbacks
		group::get -group_id $group_id -array group_array
		set group_name ${group_array(group_name)}
		regsub -all " " $group_name "_" group_name
		regsub -all {[^-a-zA-Z0-9_]} $group_name "" group_name
		
		if {[info exists contact::${object_type}_${group_array(group_name)}_new]} {
		    callback contact::${object_type}_${group_array(group_name)}_new -package_id $package_id -contact_id [set ${object_type}_party_id]
		}
	    }
	}

	# For employees we need to correctly save the relationship
	if {$orig_object_type eq "employee"} {
	    set rel_type "contact_rels_employment"
	    set party_id $person_party_id
	    set object_id_two $organization_party_id
	    set object_type "person"
	}
	    
	# Insert the relationship
	if {[exists_and_not_null rel_type] && [exists_and_not_null object_id_two]} {
	    set rel_id {}
	    set context_id {}
	    set creation_user [ad_conn user_id]
	    set creation_ip [ad_conn peeraddr]
	    set rel_id [db_exec_plsql create_rel "select acs_rel__new (
                     :rel_id,
                     :rel_type,
                     :party_id,
                     :object_id_two,
                     :context_id,
                     :creation_user,
                     :creation_ip  
                    )"]
		
	    if {[exists_and_not_null rel_type]} {
		ams::ad_form::save -package_key "contacts" \
		    -object_type $rel_type \
		    -list_name [ad_conn package_id] \
		    -form_name "party_ae" \
		    -object_id $rel_id
	    }
	    
	    callback contact::${object_type}_new_rel -object_id_two $object_id_two -rel_type $rel_type -party_id $party_id -package_id $package_id
	    contact::flush -party_id $object_id_two
	}

	# Add the user to the
	set contact_link [contact::link -party_id $party_id]
	set object_type [_ contacts.$object_type]
	util_user_message -html -message "[_ contacts.lt_The_-object_type-_-contact_link-_was_added]"

	if { [parameter::get -boolean -package_id $package_id -parameter "ContactPrivacyEnabledP" -default "0"] } {
	    set contact_privacy_settings [template::element::get_values party_ae contact_privacy_settings]
	    set gone_p 0
	    set email_p 1
	    set mail_p 1
	    set phone_p 1
	    if { [lsearch $contact_privacy_settings gone_p] >= 0 } {
		set gone_p 1
		set email_p 0
		set mail_p 0
		set phone_p 0
	    } else {
		if { [lsearch $contact_privacy_settings email_p] >= 0 } {
		    set email_p 0
		}
		if { [lsearch $contact_privacy_settings mail_p] >= 0 } {
		    set mail_p 0
		}
		if { [lsearch $contact_privacy_settings phone_p] >= 0 } {
		    set phone_p 0
		}
	    }
	    contact::privacy_set \
		-party_id $party_id \
		-email_p $email_p \
		-mail_p $mail_p \
		-phone_p $phone_p \
		-gone_p $gone_p
	}

    } -after_submit {
	contact::flush -party_id $party_id
	contact::search::flush_results_counts

	callback contact::contact_form_after_submit -party_id $party_id -package_id $package_id -object_type $object_type -form "party_ae"
	if {$orig_object_type eq "employee"} {
	    callback contact::contact_form_after_submit -party_id $organization_party_id -package_id $package_id -object_type organization -form "party_ae"
	}
	if {[empty_string_p $object_id_two]} {
	    ad_returnredirect [contact::url -party_id $party_id]
	} else {
	    ad_returnredirect "${package_url}/$object_id_two"
	}
	ad_script_abort
    }

ad_return_template
