ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {object_id:integer,multiple,optional}
    {party_id:multiple,optional}
    {party_ids ""}
    {message_type ""}
    {message:optional}
    {header_id:integer ""}
    {footer_id:integer ""}
    {return_url "./"}
    {file_ids ""}
    {files_extend:integer,multiple,optional ""}
    {item_id:integer ""}
    {folder_id:integer ""}
    {signature_id:integer ""}
    {subject ""}
    {content_body:html ""}
    {to:integer,multiple,optional ""}
    {page:optional 1}
    {context_id:integer ""}
    {cc ""}
    {bcc ""}
} -validate {
    valid_message_type -requires {message_type} {
	if { ![db_0or1row check_for_it { select 1 from contact_message_types where message_type = :message_type and message_type not in ('header','footer') }] } {
	    ad_complain "[_ contacts.lt_Your_provided_an_inva]"
	}
    }
}

if { [exists_and_not_null message] && ![exists_and_not_null message_type] } {
    set message_type [lindex [split $message "."] 0]
    set item_id [lindex [split $message "."] 1]
}

if {[empty_string_p $party_ids]} {
    set party_ids [list]
}

if { [exists_and_not_null party_id] } {
    foreach p_id $party_id {
	if {[lsearch $party_ids $party_id] < 0} {
	    lappend party_ids $p_id
	}
    }
}
	
if { [exists_and_not_null to] } {
    foreach party_id $to {
	lappend party_ids $party_id
    }
}

set invalid_party_ids  [list]

foreach id $party_ids {
    if {[contact::visible_p -party_id $id -package_id [ad_conn package_id]]} {
	lappend valid_party_ids $id
    } else {
	append invalid_party_ids $id
    }
}

set party_count [llength $party_ids]
set title "[_ contacts.Messages]"
set user_id [ad_conn user_id]
set context [list $title]

set recipients  [list]

if {![exists_and_not_null valid_party_ids]} {
    ad_return_error "[_ contacts.No_valid_parties]" "[_ contacts.No_valid_parties_lt]"
    ad_script_abort
}

foreach party_id $valid_party_ids {
    set contact_name   [contact::name -party_id $party_id]
    set contact_url    [contact::url -party_id $party_id]
    set contact_link   "<a href=\"${contact_url}\">${contact_name}</a>"
    set sort_key       [string toupper $contact_name]
    # Check if the party has a valid e-mail address we can send to
    lappend recipients [list $contact_name $party_id $contact_link]
}

set sorted_recipients  [ams::util::sort_list_of_lists -list $recipients]
set recipients         [list]
set invalid_recipients [list]
set party_ids          [list]


foreach recipient $sorted_recipients {
    set party_id       [lindex $recipient 1]
    set contact_link   [lindex $recipient 2]
    if { [lsearch [list "letter" "label" "envelope"] $message_type] >= 0 } {

	# Check if we can send a letter to this party
	set letter_p  [contact::message::mailing_address_exists_p -party_id $party_id]
        if { $letter_p } {
            lappend party_ids $party_id
            lappend recipients $contact_link
        } else {
            lappend invalid_party_ids $party_id
            lappend invalid_recipients $contact_link
        }

    } elseif { $message_type == "email" } {
	
        if { [party::email -party_id $party_id] eq "" } {
	    # We are going to check if there is an employee relationship
	    # if there is we are going to check if the employer has an
	    # email adrres, if it does we are going to use that address
	    set employer_id [lindex [contact::util::get_employee_organization -employee_id $party_id] 0]

	    if { ![empty_string_p $employer_id] } {
		set emp_addr [contact::email -party_id $employer_id]
		if { ![empty_string_p $emp_addr] } {
		    lappend party_ids $employer_id
		    lappend recipients $contact_link
		} else {
		    lappend invalid_party_ids $party_id
		    lappend invalid_recipients $contact_link
		}
	    } else {
		lappend invalid_party_ids $party_id
		lappend invalid_recipients $contact_link
	    }
        } else {
	    lappend party_ids $party_id
            lappend recipients $contact_link
        } 

    } else {
	# We are unsure what to send, so just assume for the time being we can send it to them
	lappend party_ids $party_id
	lappend recipients $contact_link
    }
}

set recipients [join $recipients ", "]
set invalid_recipients [join $invalid_recipients ", "]
if { [llength $invalid_recipients] > 0 } {
    switch $message_type {
	letter {
	    set error_message [_ contacts.lt_You_cannot_send_a_letter_to_invalid_recipients]
	}
	email {
	    set error_message [_ contacts.lt_You_cannot_send_an_email_to_invalid_recipients]
	}
	default {
	    set error_message [_ contacts.lt_You_cannot_send_a_message_to_invalid_recipients]
	}
    }
    if { $party_ids != "" } {
	util_user_message -html -message $error_message
    }
}

if {[exists_and_not_null object_id]} {
    foreach object $object_id {
	if {[fs::folder_p -object_id $object]} {
	    db_foreach files "select r.revision_id
	    from cr_revisions r, cr_items i
	    where r.item_id = i.item_id and i.parent_id = :object" {
		lappend file_list $revision_id
	    }
	} else {
	    set revision_id [content::item::get_best_revision -item_id $object]
	    if {[empty_string_p $revision_id]} {
		# so already is a revision
		lappend file_list $object
	    } else {
		# append revision of content item
		lappend file_list $revision_id
	    }
	}
    }
    # If we have files we need to unset the object_id
    set object_id ""
} else {
    set object_id ""
}

if {[exists_and_not_null file_list]} {
    set file_ids [join $file_list " "]
}

set form_elements {
    file_ids:text(hidden)
    party_ids:text(hidden)
    return_url:text(hidden)
    folder_id:text(hidden)
    object_id:text(hidden)
    context_id:text(hidden)
    {to_name:text(inform),optional {label "[_ contacts.Recipients]"} {value $recipients}}
}


if { ![exists_and_not_null message_type] } {

    set message_type_options [ams::util::localize_and_sort_list_of_lists \
				  -list [db_list_of_lists get_message_types { select pretty_name, message_type from contact_message_types }] \
				 ]

    set message_options [list]
    foreach op $message_type_options {
	set message_type [lindex $op 1]
	if { [lsearch [list "header" "footer"] $message_type] < 0 } {
	    lappend message_options [list "-- [_ contacts.New] [lindex $op 0] --" $message_type]
	} else {
	    set ${message_type}_options [list [list [_ contacts.--none--] ""]]
	}
	
	# set email_text and letter_text and others in the future
	set "${message_type}_text" [lindex $op 0]
    }

    set public_text [_ contacts.Public]
    set package_id [ad_conn package_id]
    set letter_options ""
    set email_options ""
    set oo_mailing_options ""
    db_foreach get_messages {
	select CASE WHEN owner_id = :package_id THEN :public_text ELSE contact__name(owner_id) END as public_display,
	title,
	to_char(item_id,'FM9999999999999999999999') as item_id,
	message_type
	from contact_messages
	where owner_id in ( select party_id from parties )
	or owner_id = :package_id
	order by CASE WHEN owner_id = :package_id THEN '000000000' ELSE upper(contact__name(owner_id)) END, message_type, upper(title)
    } {
        # The oo_mailing message type is used if you have a mailing template as defined in /lib/oo_mailing
	if {$message_type == "letter" || $message_type == "email" || $message_type == "oo_mailing"} {
	    lappend ${message_type}_options [list "$public_display [set ${message_type}_text]:$title" "${message_type}.$item_id"]
	} else {
	    lappend ${message_type}_options [list "$public_display:$title" "$item_id"]
	}
    }

    set message_options [concat \
			     $message_options \
			     $letter_options \
			     $email_options \
                             $oo_mailing_options]

    if {[exists_and_not_null header_options]} {
	lappend form_elements [list \
			       header_id:text(select) \
			       [list label "[_ contacts.Header]"] \
			       [list options $header_options] \
			      ]
    }

    lappend form_elements [list \
			       message:text(select) \
			       [list label "[_ contacts.Message]"] \
			       [list options $message_options] \
			      ]

    set message_type ""
    set title [_ contacts.create_a_message]

} else {
    set title [_ contacts.create_$message_type]
}

set context [list $title]

if { [string is false [exists_and_not_null message]] } {
    set signature_list [list [list [_ contacts.--none--] ""]]
    set reset_title $title
    set reset_signature_id $signature_id
    db_foreach signatures "select title, signature_id, default_p
      from contact_signatures
     where party_id = :user_id
     order by default_p, upper(title), upper(signature)" {
         lappend signature_list [list $title $signature_id]
         if { $default_p == "t" } {
             set default_signature_id $signature_id
         }
     }
    set title $reset_title
    set signature_id $reset_signature_id
    append form_elements {
	{signature_id:text(select) 
	    {label "[_ contacts.Signature]"}
	    {options {$signature_list}}
	}
    }
}

if {[exists_and_not_null footer_options]} {
    lappend form_elements [list \
			       footer_id:text(select) \
			       [list label "[_ contacts.Footer]"] \
			       [list options $footer_options] \
			      ]
}

set edit_buttons [list [list "[_ contacts.Next]" create]]

# the message form will rest party_ids so we need to carry it over
set new_party_ids $party_ids
ad_form -action message \
    -name message \
    -cancel_label "[_ contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
        if { [exists_and_not_null default_signature_id] } {
            set signature_id $default_signature_id
        } else {
            set signature_id ""
        }
    } -new_request {
    } -edit_request {
    } -on_submit {
    }
set party_ids $new_party_ids

if {[exists_and_not_null signature_id]} {
    set signature [contact::signature::get -signature_id $signature_id]
} else {
    set signature ""
}

