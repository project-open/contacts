ad_page_contract {
    Redirect page for adding users to the permissions list.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
} {
    object_id:integer
}

set page_title "[_ contacts.Add_User]"

set context [list [list [export_vars -base permissions { object_id }] "[_ contacts.Permissions]"] $page_title]

