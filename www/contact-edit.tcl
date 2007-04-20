ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$


} {
    {party_id:integer,notnull}
    {return_url ""}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] && ![ad_form_new_p -key party_id] } {
	    ad_complain "[_ contacts.lt_The_contact_specified]"
	}
    }
}
contact::require_visiblity -party_id $party_id


set object_type [contact::type -party_id $party_id]
if { $object_type == "user" } {
    set object_type "person"
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

set groups_belonging_to [db_list get_party_groups { select group_id from group_distinct_member_map where member_id = :party_id }]

set form_elements {party_id:key}
lappend form_elements {object_type:text(hidden)}

set default_group_id [contacts::default_group]
if {![permission::permission_p -object_id $default_group_id -party_id $user_id -privilege "write"]} {
    if {$user_change_p} {
	# Check if the user is editing himself
	# If not, redirect to the return_url
	if {![string eq $party_id $user_id]} {
	    ad_return_redirect $return_url
	}
    } else {
	ad_return_redirect $return_url
    }
}


set ams_forms [list "${package_id}__$default_group_id"]
foreach group [contact::groups -expand "all" -privilege_required "write" -package_id $package_id -party_id $party_id] {
    set group_id [lindex $group 1]
    if { [lsearch $groups_belonging_to $group_id] >= 0 } {
        lappend ams_forms "${package_id}__${group_id}"
    }
}


append form_elements " [ams::ad_form::elements -package_key "contacts" -object_type $object_type -list_names $ams_forms]"


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

    lappend form_elements [list contact_privacy_settings:boolean(checkbox),multiple,optional \
			       [list label [_ contacts.Privacy_Settings]] \
			       [list options $privacy_setting_options] \
			      ]
}

ad_form -name party_ae \
    -mode "edit" \
    -export {return_url} \
    -form $form_elements \
    -has_edit "1"

foreach group_id $groups_belonging_to {
    set element_name "category_ids$group_id"
    if {$group_id < 0} {
	set element_name "category_ids[expr - $group_id]"
    }

    category::ad_form::add_widgets \
	-container_object_id $group_id \
	-categorized_object_id $party_id \
	-form_name party_ae \
	-element_name $element_name
}

callback contact::contact_form -package_id $package_id -form party_ae -object_type $object_type -party_id $party_id

ad_form -extend -name party_ae \
    -on_request {

	if { $object_type == "person" }	{
	    set required_attributes [list first_names last_name email]
	} else {
	    set required_attributes [list name]
	}

	set missing_elements [list]
	foreach attribute $required_attributes {
	    if { [string is false [template::element::exists party_ae $attribute]] } {
		lappend missing_elements $attribute
	    }
	}
	# make the error message multiple item aware
	if { [llength $missing_elements] > 0 } {
	    ad_return_error "[_ contacts.Configuration_Error]" "[_ contacts.lt_Some_of_the_required__1]<ul><li>[join $missing_elements "</li><li>"]</li></ul>" 
	}

	if { [db_0or1row select_privacy_settings { select * from contact_privacy where party_id = :party_id }] } {
	    set contact_privacy_settings [list]
	    if { [string is false $email_p] } { lappend contact_privacy_settings email_p }
	    if { [string is false $mail_p] } { lappend contact_privacy_settings mail_p }
	    if { [string is false $phone_p] } { lappend contact_privacy_settings phone_p }
	    if { [string is true $gone_p] } { lappend contact_privacy_settings gone_p }
	}
    } -edit_request {
        set revision_id [contact::live_revision -party_id $party_id]
        foreach form $ams_forms {
            ams::ad_form::values -package_key "contacts" \
                -object_type $object_type \
                -list_name $form \
                -form_name "party_ae" \
                -object_id $revision_id
        }
        callback contact::special_attributes::ad_form_values -party_id $party_id -form "party_ae"
        
    } -on_submit {

	# WE NEED TO MAKE SURE THAT VALUES THAT NEED TO BE UNIQUE ARE UNIQUE

	# for orgs name needs to be unique
	# for all of them email needs to be unique

	if { $object_type == "person" } {
	    if { ![exists_and_not_null first_names] } {
		template::element::set_error party_ae first_names "[_ contacts.lt_First_Names_is_requir]"
	    }
	    if { ![exists_and_not_null last_name] } {
		template::element::set_error party_ae last_name "[_ contacts.lt_Last_Name_is_required]"
	    }
	} else {
	    if { ![exists_and_not_null name] } {
		template::element::set_error party_ae name "[_ contacts.Name_is_required]"
	    }
	}
	if { ![template::form::is_valid party_ae] } {
	    break
	}

    } -new_data {
    } -edit_data {
	callback contact::special_attributes::ad_form_save -party_id $party_id -form "party_ae"

        set previous_revision_id [contact::live_revision -party_id $party_id]
        set revision_id [contact::revision::new -party_id $party_id]

	# we copy all the attributes from the old id to the new one
        # a user may not have permission to view all attributes
        # for a contact, and this way the values of the attributes
        # they do not have permission to edit are preserved the follwing
        # foreach saves the values they have edited
	ams::object_copy -from $previous_revision_id -to $revision_id
	

        foreach form $ams_forms {
            ams::ad_form::save -package_key "contacts" \
                -object_type $object_type \
                -list_name $form \
                -form_name "party_ae" \
                -object_id $revision_id
        }
	
	# We need to flush the cache for every attribute_id that this party has
	set flush_attribute_list [db_list_of_lists get_attribute_ids {
	    select
	    distinct
	    ams_a.attribute_id
	    from
	    ams_attribute_values ams_a,
	    ams_attribute_values ams_b,
	    acs_objects o
	    where
	    ams_a.object_id = ams_b.object_id
	    and ams_b.object_id = o.object_id
	    and o.context_id = :party_id
	}]
	
	foreach attr_id $flush_attribute_list {
	    util_memoize_flush [list ams::values_not_cached \
				    -package_key "contacts" \
				    -object_type $object_type \
				    -object_id $attr_id]
	}
	
	set contact_link [contact::link -party_id $party_id]
	util_user_message -html -message [_ contacts.lt_contact_link_was_updated]

	set cat_ids [list]
	foreach group_id $groups_belonging_to {
	    set element_name "category_ids$group_id"
	    if {$group_id < 0} {
		set element_name "category_ids[expr - $group_id]"
	    }

	    set cat_ids [concat $cat_ids \
			     [category::ad_form::get_categories \
				  -container_object_id $group_id \
				  -element_name $element_name]]
	}

	category::map_object -remove_old -object_id $party_id $cat_ids
	if {$object_type == "organization"} {
	    callback contact::organization_new -package_id $package_id -contact_id $party_id -name $name
	    foreach employee_id [contact::util::get_employees -organization_id $party_id] {
		contact::flush -party_id $employee_id
	    }
	} else {
	    callback contact::person_add -package_id $package_id -person_id $party_id
	}
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

	if { ![exists_and_not_null return_url] } {
	    set return_url [contact::url -party_id $party_id] 
	}

        ad_returnredirect $return_url
	ad_script_abort
    }












ad_return_template
