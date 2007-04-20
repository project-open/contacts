ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {signature_id:integer,optional}
} -validate {
    valid_signature_id -requires {signature_id} {
	set party_id [ad_conn user_id]
	if { ![ad_form_new_p -key signature_id] } {
	    if { [string is false [db_0or1row sig_is_mine_p {select '1' from contact_signatures where signature_id = :signature_id and party_id = :party_id}]] } {
		ad_complain "[_ contacts.lt_This_signature_specif]"
	    }
	}
    }
}


if { [ad_form_new_p -key signature_id] } {
    set page_title "[_ contacts.Create_a_Signature]"
    set edit_buttons [list [list "[_ contacts.Create]" save]]
} else {
    set page_title "[_ contacts.Edit_a_Signature]"
    set edit_buttons [list [list "[_ contacts.Save]" save] [list "[_ contacts.Delete]" delete]]
}

set context [list $page_title]
set party_id [ad_conn user_id]
set form_elements {
    signature_id:key
    {title:text(text) {label "[_ contacts.Save_As]"} {html {size 35 maxlength 35}}}
    {signature:richtext(richtext) {label "[_ contacts.Signature]"} {html {cols 45 rows 5}}}
    {default_p:boolean(checkbox),optional {label ""} {options {{{[_ contacts.lt_this_is_my_default_si]} 1}}}}
}


ad_form -action signature \
    -name signature \
    -cancel_label "[_ contacts.Cancel]" \
    -cancel_url "settings" \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -new_request {
    } -edit_request {
	db_1row get_sig_info { select * from contact_signatures where signature_id = :signature_id }
    } -on_submit {
	if { [ns_queryget "formbutton:delete"] != "" } {
	    db_dml delete_it { delete from contact_signatures where signature_id = :signature_id and party_id = :party_id }
	    ad_returnredirect "settings"
	    ad_script_abort
	}
	if { [string is false [exists_and_not_null default_p]] } {
	    set default_p 0
	} else {
	    # its true and we reset the default
	    db_dml update_defaults { update contact_signatures set default_p = 'f' where party_id = :party_id }
	}
    } -new_data {
	db_dml insert_sig { insert into contact_signatures values ( :signature_id, :title, :signature, :default_p, :party_id ) }
    } -edit_data {
	db_dml update_sig { update contact_signatures set title = :title, signature = :signature, default_p = :default_p where signature_id = :signature_id }
    } -after_submit {
	ad_returnredirect "settings"
    }

