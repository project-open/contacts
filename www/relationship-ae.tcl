ad_page_contract {
    Add a Relationship and Manage Relationship Details

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-05-21
    @cvs-id $Id$
} {
    {object_id_one:integer,notnull}
    {object_id_two:integer,notnull}
    {party_id:integer,notnull}
    {rel_type:notnull}
    {return_url ""}
} -validate {
    contact_one_exists -requires {object_id_one} {
	if { ![contact::exists_p -party_id $object_id_one] } {
	    ad_complain "[_ contacts.lt_The_first_contact_spe]"
	}
    }
    contact_two_exists -requires {object_id_two} {
	if { ![contact::exists_p -party_id $object_id_two] } {
	    ad_complain "[_ contacts.lt_The_second_contact_sp]"
	}
    }
    party_id_valid -requires {object_id_one object_id_two party_id} {
	if { $party_id != $object_id_one && $party_id != $object_id_two } {
	    ad_complain "[_ contacts.lt_The_contact_specified_1]"
	}
    }
}



contact::require_visiblity -party_id $object_id_one
contact::require_visiblity -party_id $object_id_two

set rel_id_from_db [db_string get_rel_id {} -default {}]
if { [exists_and_not_null rel_id_from_db] } {
    set rel_id $rel_id_from_db
}
set package_id [ad_conn package_id]
set list_exists_p [ams::list::exists_p -package_key "contacts" -object_type ${rel_type} -list_name ${package_id}]

if { $list_exists_p } {

    set form_elements {
        rel_id:key
        {object_id_one:integer(hidden)}
        {object_id_two:integer(hidden)}
        {party_id:integer(hidden)}
        {rel_type:text(hidden)}
    }
    append form_elements [ams::ad_form::elements -package_key "contacts" -object_type $rel_type -list_name [ad_conn package_id]]

    ad_form -name rel_form \
        -mode "edit" \
        -form $form_elements \
	-export {return_url} \
        -on_request {
        } -new_request {
        } -edit_request {
            ams::ad_form::values -form_name "rel_form" -package_key "contacts" -object_type $rel_type -list_name [ad_conn package_id] -object_id $rel_id
        } -on_submit {
        } -new_data {
        } -edit_data {
        } -after_submit {
        }
    

}

if { !$list_exists_p || [template::form::is_valid "rel_form"] } {

    set existing_rel_id [db_string rel_exists_p {} -default {}]

    if { [empty_string_p $existing_rel_id] } {
        set rel_id {}
        set context_id {}
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]
        set rel_id [db_exec_plsql create_rel {}]
        db_dml insert_contact_rel {}
        set message [_ contacts.Relationship_Added]
        #       callback contact::insert_contact_rel -package_id $package_id -form party_ae -object_type $object_type
    } else {
        set message [_ contacts.Relationship_Updated]
    }
    if { $list_exists_p } {
        ams::ad_form::save -package_key "contacts" \
            -object_type $rel_type \
            -list_name [ad_conn package_id] \
            -form_name "rel_form" \
            -object_id $rel_id
    }

    # flush info on the parties
    contact::flush -party_id $object_id_one
    contact::flush -party_id $object_id_two

    # send them on their way
    if { ![exists_and_not_null return_url] } {
        set return_url "[contact::url -party_id $party_id -package_id $package_id]relationships"
    }
    set redirect_rel_types [parameter::get -parameter EditDataAfterRel -package_id [ad_conn package_id] -default ""]

    if { [regexp {\*} $redirect_rel_types match] || [lsearch $redirect_rel_types $rel_type] >= 0 } {
        # we need to redirect the party to the attribute add/edit page
        set return_url [export_vars -base "[contact::url -party_id $party_id -package_id $package_id]edit" -url {return_url}]
        append message ". [_ contacts.lt_update_contact_if_needed]"
    }

    # they have the special contact spouse rel enabled
    if { $rel_type eq "contact_rels_spouse" && [contacts::spouse_enabled_p -package_id $package_id] } {
	set return_url [export_vars -base "[contact::url -party_id $party_id]spouse-sync"]
    }

    util_user_message -message $message
    ad_returnredirect $return_url
    ad_script_abort
}

ad_return_template
