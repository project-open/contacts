#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-05-09
#    @cvs-id $Id$


set contacts_master_template [parameter::get_from_package_key -package_key "contacts" -parameter "ContactsMaster" -default "/packages/contacts/lib/contacts-master"]
if { $contacts_master_template != "/packages/contacts/lib/contacts-master" } {
    ad_return_template
}

# Set up links in the navbar that the user has access to
set package_url [ad_conn package_url]

set link_list [list]
lappend link_list "${package_url}"
lappend link_list "[_ contacts.Contacts]"
lappend link_list "contacts"
lappend link_list ""

if { ![parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {
    set addlist [list [list [list "text" "[_ contacts.Add_Employee]"] [list "url" "${package_url}add/employee"] ] \
		     [list [list "text" "[_ contacts.Add_Person]"] [list "url" "${package_url}add/person"] ] \
		     [list [list "text" "[_ contacts.Add_Organization]"] [list "url" "${package_url}add/organization"] ] \
		     ]
    
    ah::yui::menu_from_list -varname "oMenu1" \
	-id "basicmenu1" \
	-menulist $addlist \
	-arrayname "yuimenu1" \
	-options "context:new Array(\"menu1\",\"tl\",\"bl\"),hidedelay:1" \
	-css "/resources/contacts/yuimenu/menu.css"

        
    set action_script1 $yuimenu1(show)

    lappend link_list "javascript:void(0)" ; # HREF
    lappend link_list "[_ contacts.Add]" ; # Title
    lappend link_list "menu1" ; # ID
    lappend link_list "$action_script1" ; # Mouseover
}

set addlist [list [list [list "text" "[_ contacts.Advanced_Search]"] [list "url" "${package_url}search"] ] \
		 [list [list "text" "[_ contacts.Saved_Searches]"] [list "url" "${package_url}searches"] ] \
		]

ah::yui::menu_from_list -varname "oMenu2" \
    -id "basicmenu2" \
    -menulist $addlist \
    -arrayname "yuimenu2" \
    -options "context:new Array(\"menu2\",\"tl\",\"bl\"),hidedelay:1" \
    -css "/resources/contacts/yuimenu/menu.css"

set action_script1 $yuimenu2(show)

lappend link_list "javascript:void(0)" ; # HREF
lappend link_list "[_ contacts.Search]" ; # Title
lappend link_list "menu2" ; # ID
lappend link_list "$action_script1" ; # Mouseover


# this should be taken care of by a callback...
if { [apm_package_enabled_p tasks] } {
    lappend link_list "${package_url}tasks"
    lappend link_list "[_ tasks.Tasks]"
    lappend link_list "tasks"
    lappend link_list ""
    
    lappend link_list "${package_url}processes"
    lappend link_list "[_ tasks.Processes]"
    lappend link_list "processes"
    lappend link_list ""
}

lappend link_list "${package_url}messages"
lappend link_list "[_ contacts.Messages]"
lappend link_list "messages"
lappend link_list ""

lappend link_list "${package_url}settings"
lappend link_list "[_ contacts.Settings]"
lappend link_list "settings"
lappend link_list ""

if { [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
    lappend link_list "${package_url}admin/"
    lappend link_list "[_ contacts.Admin]"
    lappend link_list "admin"
    lappend link_list ""
}



set page_url [ad_conn url]
set page_query [ad_conn query]

# Convert the list to a multirow and add the selected_p attribute
multirow create links label url id mouseover selected_p

set navbar {}
foreach {url label id mouseover} $link_list {
    set selected_p 0

    if {[string equal $page_url $url]} {
        set selected_p 1
        if { ${url} == ${package_url} } {
	    set title [ad_conn instance_name]
        } else {
	    set title $label
	}
    }
    lappend navbar [list [subst $url] $label]
    multirow append links $label [subst $url] $id $mouseover $selected_p
}

if { [parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {
    if { $page_url == "${package_url}add/person" } {
	    set title [_ contacts.Add_Person]
    } elseif { $page_url == "${package_url}add/organization" } {
	    set title [_ contacts.Add_Organization]
    }
}

if { ![exists_and_not_null title] } {
    set title [ad_conn instance_name]
    set context [list]
} else {
    set context [list $title]
}


# Finalize the Javascript menus
set js_script $yuimenu1(render)
append js_script $yuimenu2(render)
set js_script [ah::enclose_in_script -script ${js_script} ]

ad_return_template
