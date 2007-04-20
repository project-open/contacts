set required_param_list [list]
set optional_param_list [list base_url extend_p extend_values attr_val_name]
set default_param_list  [list orderby format query page page_size package_id search_id group_id]
set optional_unset_list [list]

# default values for default params
set _orderby "first_names,asc"
set _format "normal"
set _page_size "25"
set admin_p 0


if { [string is false [exists_and_not_null package_id]] } {
    set package_id [ad_conn package_id]
}

foreach required_param $required_param_list {
    set $required_param [ns_queryget $default_param]
    if { ![exists_and_not_null required_param] } {
	return -code error "$required_param is a required parameter."
    }
}

foreach optional_param $optional_param_list {
    if { ![exists_and_not_null ${optional_param}] } {
	set $optional_param ""
    }
}

foreach default_param $default_param_list {
    set $default_param [ns_queryget $default_param]
    if { ![exists_and_not_null ${default_param}] && [exists_and_not_null "_${default_param}"] } {
	set $default_param [set _${default_param}]
    }
}

# if a double colon is in the query then the paginator messes up because it evals
# the page string and attempts to run it as a proc, so we remove all double colons
# here.
while { [regsub -all {::} $query {:} query] } {}


# see if the person is attemping to add
# or remove a column
set extended_columns [ns_queryget extended_columns]
set add_column       [ns_queryget add_column]
set remove_column    [ns_queryget remove_column]
if { $extended_columns ne "" && $remove_column ne "" } {
    set lindex_id [lsearch -exact $extended_columns $remove_column]
    if { $lindex_id >= 0 } {
	set extended_columns [lreplace $extended_columns $lindex_id $lindex_id]
    }
}
if { $add_column ne "" } {
    lappend extended_columns $add_column
}

set add_column ""
set remove_column ""

set report_p [ns_queryget report_p]
if { [string is true $report_p] && $report_p ne "" } {
    set report_csv_url    [export_vars -base $base_url -url {{format csv} search_id query page page_size extended_columns orderby {report_p 1}}]
    set contacts_mode_url [export_vars -base $base_url -url {format search_id query page page_size extended_columns orderby {report_p 0}}]
} else {
    set report_p 0
    set report_mode_url [export_vars -base $base_url -url {format search_id query page page_size extended_columns orderby {report_p 1}}]
}




# This is for showing the employee_id and employeer relationship
set condition_type_list [db_list get_condition_types {}] 

if { ![string equal [lsearch -exact $condition_type_list "employees"] "-1"] } {
    set multirow_query_name "employees_select"
} else {
    set multirow_query_name "contacts_select"
}

# If we do not have a search_id, limit the list to only users in the default group.
if {[exists_and_not_null search_id]} {
    # Also we can extend this search.
    # Is to allow extend the list by any extend_options defined in contact_extend_options
    set extend_options [contact::extend::get_options \
				    -ignore_extends $extend_values \
				    -search_id $search_id -aggregated_p "f"]
    if { [llength $extend_options] == 0 } {
	set hide_form_p 1
    }

    set available_options [concat \
			       [list [list "- - - - - - - -" ""]] \
			       $extend_options \
			       ]

    ad_form -name extend -form {
	{extend_option:text(select),optional
	    {label "[_ contacts.Available_Options]" }
	    {options {$available_options}}
	}
	{search_id:text(hidden)
	    {value "$search_id"}
	}
	{extend_values:text(hidden)
	    {value "$extend_values"}
	}
    } -on_submit {
	# We clear the list when no value is submited, otherwise
	# we acumulate the extend values.
	if { [empty_string_p $extend_option] } {
	    set extend_values [list]
	} else {
	    lappend extend_values [list $extend_option] 
	}
	ad_returnredirect [export_vars -base "?" {search_id extend_values extended_columns}]
    }
}


set group_by_group_id ""
if { ![exists_and_not_null group_id] } {
    set where_group_id " = [contacts::default_group]"
} else {
    if {[llength $group_id] > 1} {
	set where_group_id " IN ('[join $group_id "','"]')"
	set group_by_group_id "group by parties.party_id , parties.email"
    } else {
	set where_group_id " = :group_id"
    }
}


set last_modified_join ""
set last_modified_clause ""
set last_modified_rows ""

template::multirow create bulk_acts pretty link detailed
template::multirow append bulk_acts "[_ contacts.Add_to_Group]" "${base_url}group-parties-add" "[_ contacts.Add_to_group]"
template::multirow append bulk_acts "[_ contacts.Remove_From_Group]" "${base_url}group-parties-remove" "[_ contacts.lt_Remove_from_this_Grou]"
template::multirow append bulk_acts "[_ contacts.Add_to_List]" "${base_url}list-parties-add" "[_ contacts.Add_to_List]"
template::multirow append bulk_acts "[_ contacts.Remove_from_List]" "${base_url}list-parties-remove" "[_ contacts.Remove_from_List]"
template::multirow append bulk_acts "[_ contacts.Add_Relationship]" "${base_url}relationship-bulk-add" "[_ contacts.lt_Add_relationship_to_sel]"
template::multirow append bulk_acts "[_ contacts.Mail_Merge]" "${base_url}message" "[_ contacts.lt_E-mail_or_Mail_the_se]"
if { [permission::permission_p -object_id $package_id -privilege "admin"] || [acs_user::site_wide_admin_p]  } {
    set admin_p 1
    template::multirow append bulk_acts "[_ contacts.Bulk_Update]" "${base_url}bulk-update" "[_ contacts.lt_Bulk_update_the_seclected_C]"
}
callback contacts::bulk_actions -multirow "bulk_acts"

set bulk_actions [list]
template::multirow foreach bulk_acts {
    lappend bulk_actions $pretty $link $detailed
}

set return_url "[ad_conn url]?[ad_conn query]"



# Delete file is not there, taking out the code to display the delete button
# if { [permission::permission_p -object_id $package_id -privilege "delete"] } {
#    lappend bulk_actions "[_ contacts.Delete]" "${base_url}delete" "[_ contacts.lt_Delete_the_selected_C]"
# }
if { [exists_and_not_null search_id] } {

    set object_type [db_string get_object_type {} -default {party}]
    set actual_object_type $object_type
    switch $object_type {
	person { 
            set page_query_name "person_pagination"
            if {[string eq $orderby "organization,asc"]} {
		set orderby "first_names,asc"
            }
            # set default_attr_extend [parameter::get -parameter "DefaultPersonAttributeExtension"]
	    set party_column "persons.person_id"
	    set item_column "persons.person_id"
	}
	organization { 
	    set page_query_name "organization_pagination"
	    if {[string eq $orderby "first_names,asc"] || [string eq $orderby "last_name,asc"]} {
		set orderby "organization,asc"
	    }
            # set default_attr_extend [parameter::get -parameter "DefaultOrganizationAttributeExtension"]
	    set party_column "organizations.organization_id"
	    set item_column "organizations.organization_id"
	}
	party { 
	    set page_query_name "contacts_pagination"
            # set default_attr_extend [parameter::get -parameter "DefaultPersonOrganAttributeExtension"]
	    set party_column "parties.party_id"
	    set item_column "parties.party_id"
	}
        employee {
	    set actual_object_type "organization"
	    set party_column "acs_rels.object_id_one"
	    set item_column "acs_rels.object_id_two"
	    set page_query_name "employee_pagination"
	}
    }
    set search_clause 	[contact::search_clause -and -search_id $search_id -query $query -party_id $party_column -revision_id "cr_items.live_revision" -limit_type_p "0"]
    if { $orderby eq "last_modified,desc" } {
	# we need the cr_items and cr_revisions table since we need the
        # cr_revisions.publish date
	append cr_where " and $item_column = cr_items.item_id and cr_items.live_revision = cr_revisions.revision_id"
        append cr_from " cr_items, cr_revisions,"
    } elseif {[lsearch -exact $condition_type_list "attribute"] > -1 || [lsearch -exact $condition_type_list "contact"] > -1 } {
	set cr_where "and cr_items.item_id = $item_column"
	set cr_from "cr_items,"
    } else {
	# We don't need to search for attributes so we don't need to join
	# on the cr_items table. This should speed things up. This assumes
	# that packages other than contacts that add search condition
	# types do not need the revision_id column, and only needs the
	# party_id column. If this is not the case we may want to add a
	# callback here to check if another package needs the revisions 
	# table.
	#
	# If this needs to change you should also update the
	# contact::search::results_count_not_cached proc which behaves the
        # same way.
	set cr_where ""
	set cr_from ""
    }
} else {
    set object_type "party"
    set actual_object_type "party"
    set page_query_name "contacts_pagination"
    set search_clause "[contact::search_clause -and -query $query -search_id "" -party_id "parties.party_id" -limit_type_p "0"]"

    if { $orderby eq "last_modified,desc" } {
	set cr_from "cr_items, cr_revisions,"
	set cr_where "and parties.party_id = cr_items.item_id and cr_items.live_revision = cr_revisions.revision_id"
    } else {
	set cr_from ""
	set cr_where ""
    }
}

set first_names_url   [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {first_names,asc}}}]
set last_name_url     [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {last_name,asc}}}]
set organization_url  [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {organization,asc}}}]
set last_modified_url [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {last_modified,desc}}}]

switch $orderby {
    "first_names,asc" {
        set name_label "[_ contacts.Sort_by] [_ contacts.First_Names] | <a href=\"${last_name_url}\">[_ contacts.Last_Name]</a> | <a href=\"${organization_url}\">[_ contacts.Organization]</a> | <a href=\"${last_modified_url}\">[_ contacts.Last_Modified]</a>"
	set left_join "left join persons on (parties.party_id = persons.person_id)"
	set sort_item "lower(persons.first_names), lower(persons.last_name)"
    }
    "last_name,asc" {
        set name_label "[_ contacts.Sort_by] <a href=\"${first_names_url}\">[_ contacts.First_Names]</a> | [_ contacts.Last_Name] | <a href=\"${organization_url}\">[_ contacts.Organization]</a> | <a href=\"${last_modified_url}\">[_ contacts.Last_Modified]</a>"
	set left_join "left join persons on (parties.party_id = persons.person_id)"
	set sort_item "lower(persons.last_name), lower(persons.first_names)"
    }
    "organization,asc" {
        set name_label "[_ contacts.Sort_by] <a href=\"${first_names_url}\">[_ contacts.First_Names]</a> | <a href=\"${last_name_url}\">[_ contacts.Last_Name]</a> | [_ contacts.Organization] | <a href=\"${last_modified_url}\">[_ contacts.Last_Modified]</a>"
	set left_join "left join organizations on (parties.party_id = organizations.organization_id)"
	set sort_item "lower(organizations.name)"
    }
    "last_modified,desc" {
        set name_label "[_ contacts.Sort_by] <a href=\"${first_names_url}\">[_ contacts.First_Names]</a> | <a href=\"${last_name_url}\">[_ contacts.Last_Name]</a> | <a href=\"${organization_url}\">[_ contacts.Organization]</a> | [_ contacts.Last_Modified]"
	set left_join ""
	set sort_item "cr_revisions.publish_date"
	set last_modified_rows [list publish_date {}]
    }
}

append name_label " &nbsp;&nbsp; [_ contacts.Show]: "

set valid_page_sizes [list 25 50 100 500]
if { ![exists_and_not_null page_size] || [lsearch $valid_page_sizes $page_size] < 0 } {
    set page_size [parameter::get -parameter "DefaultPageSize" -default "50"]
}
foreach page_s $valid_page_sizes {
    if { $page_size == $page_s } {
        lappend page_size_list $page_s
    } else {
        lappend page_size_list "<a href=\"[export_vars -base $base_url -url {format search_id query page orderby extended_columns {page_size $page_s}}]\">$page_s</a>"
    }
}
append name_label [join $page_size_list " | "]

if { [string is true [parameter::get -parameter "DisableCSV" -default "0"]] || ![acs_user::site_wide_admin_p] } {
    set format normal
} else {
    append name_label "&nbsp;&nbsp;&nbsp;[_ contacts.Get]: <a href=\"[export_vars -base $base_url -url {{format csv} search_id query page orderby page_size extended_columns}]\">[_ contacts.CSV]</a>"
}


set elements [list]
lappend elements contact [list \
			      label {<span style=\"float: right; font-weight: normal; font-size: smaller\">$name_label</a>} \
			      display_template { 
				   <a href="@contacts.contact_url@">@contacts.name;noquote@</a>@contacts.orga_info;noquote@
				   <span class="contact-editlink">
                                       \[<a href="${base_url}contact-edit?party_id=@contacts.party_id@">[_ contacts.Edit]</a>\]
				   </span>
				   <if @contacts.email@ not nil or @contacts.url@ not nil>
				       <span class="contact-attributes">
				       <if @contacts.email@ not nil>
                                           <a href="@contacts.message_url@">@contacts.email@</a>
		                       </if>
		                       <if @contacts.url@ not nil>
                                            <if @contacts.email@ not nil>
                                                 ,
                                            </if>
                                            <a href="@contacts.url@">@contacts.url@</a>
 		                       </if>
				       </span>
                        	   </if>
			      }]


lappend elements contact_id [list display_col party_id]
lappend elements first_names [list display_col first_names label [_ contacts.First_Names]]
lappend elements last_name [list display_col last_name label [_ contacts.Last_Name]]
lappend elements publish_date [list display_col publish_date label [_ contacts.Last_Modified]]
lappend elements organization [list display_col organization label [_ contacts.Organization]]
lappend elements email [list display_col email label [_ contacts.Email]]
lappend elements name [list display_col name label [_ contacts.Name]]

if { $format == "csv" } {
    set row_list [list contact_id {} name {}]
    if { $object_type ne "organization" } {
	lappend row_list first_names {} last_name {}
    }
    lappend row_list email {}
    
} else {

    set row_list [list \
		  checkbox {
		      html {style {width: 30px; text-align: center;}}
		  } \
		      contact {} \
		 ] 
}

set row_list [concat $row_list $last_modified_rows]

if { [exists_and_not_null search_id] } {
    # We get all the default values for that are mapped to this search_id
    set default_values [db_list_of_lists get_default_extends { }]
    set extend_values [concat $default_values $extend_values]
}

# For each extend value we add the element to the list and to the query
set extend_query ""
foreach value $extend_values {
    set extend_info [lindex [contact::extend::option_info -extend_id $value] 0]
    set name        [lindex $extend_info 0]
    set pretty_name [lindex $extend_info 1]
    set sub_query   [lindex $extend_info 2]
    lappend elements $name [list label "$pretty_name" display_template "@contacts.${name};noquote@"]
    lappend row_list $name [list]
    append extend_query "( $sub_query ) as $name,"
}

set date_format [lc_get formbuilder_date_format]


set actions [list]
if { $admin_p && [exists_and_not_null search_id] } {
    set actions [list "[_ contacts.Set_default_extend]" "admin/ext-search-options?search_id=$search_id" "[_ contacts.Set_default_extend]" ]
}


template::multirow create ext impl type type_pretty key key_pretty

# permissions for what attributes/extensions are visible to this
# user are to be handled by this callback proc. The callback
# MUST only return keys that are visible to this user

callback contacts::extensions \
    -user_id [ad_conn user_id] \
    -multirow ext \
    -package_id [ad_conn package_id] \
    -object_type $actual_object_type


set add_columns [list]
set remove_columns [list]
set db_extend_columns [list]
if { $search_id ne "" } {
    # now we get the extensions for this specific search
    set db_extend_columns [contact::search::get_extensions -search_id $search_id]
}
set combined_extended_columns [lsort -unique [concat $db_extend_columns $extended_columns]]

# we run through the multirow here to determine wether or not the columns are allowed
set report_elements [list]
template::multirow foreach ext {
    set selected_p 0
    set immutable_p 0
    if { [lsearch $combined_extended_columns "${type}__${key}"] >= 0 } {
        # we want to use this column in our table
        set selected_p 1
        if { [lsearch $db_extend_columns "${type}__${key}"] >= 0 } {
            set immutable_p 1
        }
        # we add the column to the template::list
        lappend elements            "${type}__${key}" [list label $key_pretty display_col "${type}__${key}" display_template "@contacts.${type}__${key};noquote@"]
	lappend report_elements     "${type}__${key}" [list label $key_pretty display_col "${type}__${key}" display_template "@report.${type}__${key};noquote@"]
	lappend row_list "${type}__${key}" [list]
    }
    if { [string is true $selected_p] && [string is false $immutable_p] } {
	lappend remove_columns [list $key_pretty "${type}__${key}" $type_pretty]
    } elseif { [string is false $selected_p] } {
	lappend add_columns [list $key_pretty "${type}__${key}" $type_pretty]
    }
}

if { [string is false $report_p] } {


    template::list::create \
	-html {width 100%} \
	-name "contacts" \
	-multirow "contacts" \
	-row_pretty_plural "[_ contacts.contacts]" \
	-checkbox_name checkbox \
	-selected_format ${format} \
	-key party_id \
	-page_size $page_size \
	-page_flush_p t \
	-page_query_name $page_query_name \
	-actions $actions \
	-bulk_actions $bulk_actions \
	-bulk_action_method post \
	-bulk_action_export_vars { search_id return_url } \
	-elements $elements \
	-filters {
	    search_id {}
	    page_size {}
	    extend_values {}
	    attribute_values {}
	    query {}
	    extended_columns {}
	} -orderby {
	    first_names {
		label "[_ contacts.First_Name]"
		orderby_asc  "lower(persons.first_names) asc, lower(persons.last_name) asc"
		orderby_desc "lower(persons.first_names) desc, lower(persons.last_name) desc"
	    }
	    last_name {
		label "[_ contacts.Last_Name]"
		orderby_asc  "lower(persons.last_name) asc, lower(persons.first_names) asc"
		orderby_desc "lower(persons.last_name) desc, lower(persons.first_names) desc"
	    }
	    organization {
		label "[_ contacts.Organization]"
		orderby_asc  "lower(organizations.name) asc"
		orderby_desc "lower(organizations.name) desc"
	    }
	    last_modified {
		label "[_ contacts.Last_Modified]"
		orderby_asc "cr_revisions.publish_date asc"
		orderby_desc "cr_revisions.publish_date desc"
	    }
	    default_value first_names,asc
	} -formats {
	    normal {
		label "[_ contacts.Table]"
		layout table
		page_size $page_size
		row {
		    $row_list
		}
	    }
	    csv {
		label "[_ contacts.CSV]"
		output csv
		page_size 64000
		row {
		    $row_list
		}
	    }
	}

    db_multirow -extend [list contact_url message_url name orga_info] -unclobber contacts $multirow_query_name {} {
	set contact_url [contact::url -party_id $party_id]
	set message_url [export_vars -base "${contact_url}message" {{message_type "email"}}]
	set name "[contact::name -party_id $party_id]"
	
	set display_employers_p [parameter::get \
				     -parameter DisplayEmployersP \
				     -package_id $package_id \
				     -default "0"]
	
	if {$display_employers_p && [person::person_p -party_id $party_id]} {
	    # We want to display the names of the organization behind the employees name
	    set organizations [contact::util::get_employers -employee_id $party_id]
	    if {[llength $organizations] > 0} {
		set orga_info {}
		
		foreach organization $organizations {
		    set organization_url [contact::url -party_id [lindex $organization 0]]
		    set organization_name [lindex $organization 1]
		    lappend orga_info "<a href=\"$organization_url\">$organization_name</a>"
		}
		
		if {![empty_string_p $orga_info]} {
		    set orga_info " - ([join $orga_info ", "])"
		}
	    }
	}
    }
    

    if { [exists_and_not_null query] && [template::multirow size contacts] == 1 } {
	# Redirecting the user directly to the one resulted contact
	ad_returnredirect [contact::url -party_id [template::multirow get contacts 1 party_id]]
	ad_script_abort
    }

    # extend the multirow
    template::list::get_reference -name contacts
    if { [empty_string_p $list_properties(page_size)] || $list_properties(page_size) == 0 } {
	# we give an alias that won't likely be used in the contacts::multirow extend callbacks
	# because those callbacks may have references to a parties table and we don't want 
	# postgresql to think that this query belongs to that table.
	set select_query "select p[ad_conn user_id].party_id from parties p[ad_conn user_id]"
    } else {
	set select_query [template::list::page_get_ids -name "contacts"]
    }

    if { $format == "csv" } {
	set extend_format "text"
    } else {
	set extend_format "html"
    }

    contacts::multirow \
	-extend $combined_extended_columns \
	-multirow contacts \
	-select_query $select_query \
	-format $extend_format
 
    list::write_output -name contacts

} else {
    if { [llength $combined_extended_columns] == "0"} {
	ad_returnredirect -message [_ contacts.lt_Aggregated_reports_require_added_columns] $contacts_mode_url
	ad_script_abort
    }


    set party_ids [list]
    db_multirow contacts report_contacts_select {} {
	lappend party_ids $party_id
    }

    if { [llength $party_ids] < 10000 } {
	# postgresql cannot deal with lists larger than 10000
	set select_query [template::util::tcl_to_sql_list $party_ids]
    } else {
	set select_query "select p[ad_conn user_id].party_id from parties p[ad_conn user_id]"
    }

    if { $format == "csv" } {
	set extend_format "text"
    } else {
	set extend_format "html"
    }

    contacts::multirow \
	-extend $combined_extended_columns \
	-multirow contacts \
	-select_query $select_query \
	-format $extend_format

    template::list::create \
	-html {width 100%} \
	-name "report" \
	-multirow "report" \
	-selected_format ${format} \
	-elements [concat $report_elements [list quantity [list label [_ contacts.Quantity]]]] \
	-formats {
	    normal {
		label "[_ contacts.Table]"
		layout table
	    }
	    csv {
		label "[_ contacts.CSV]"
		output csv
	    }
	}
    


    set command [list template::multirow create report]
    foreach {element details} $report_elements {
	lappend command $element
    }
    lappend command quantity
    eval $command

    
    set keys [list]
    template::multirow foreach contacts {
	set key [list]
	foreach {element details} $report_elements {
	    if { $element ne "party_id" } {
		lappend key [set $element]
	    }
	}
	if { [info exists quantities($key)] } {
	    incr quantities($key)
	} else {
	    set quantities($key) 1
	    lappend keys $key
	}
    }
    # now we figure out how many list items each
    # key has then then we sort recursively
    
    set count [llength $key]
    while { $count > 0 } {
	incr count -1
	set keys [lsort -dictionary -index $count $keys]
    }
    
    foreach key $keys {
	set command [list template::multirow append report]
	set count 0
	foreach part $key {
	    if { $part eq "" } {
		set part [_ contacts.--Not_Specified--]
		if { $format ne "csv" } {
		    set part "<em>${part}</em>"
		}
	    }
	    lappend command $part
	}
	lappend command $quantities($key)
	eval $command
    }
    list::write_output -name report

}





# create forms to add/remove columns from the multirow
if { [llength $add_columns] > 0 } {
    set add_columns [concat [list [list "[_ contacts.--add_column--]" "" ""]] $add_columns]
}
if { [llength $remove_columns] > 0 } {
    set remove_columns [concat [list [list "[_ contacts.--remove_column--]" "" ""]] $remove_columns]
}

set extended_columns_preserved $extended_columns
set report_p_preserved $report_p

ad_form \
    -name "add_column_form" \
    -method "GET" \
    -export {format search_id query page page_size orderby report_p} \
    -has_submit "1" \
    -has_edit "1" \
    -form {
	{extended_columns:text(hidden),optional}
	{add_column:text(select_with_optgroup)
	    {label ""}
	    {html {onChange "document.add_column_form.submit();"}}
	    {options $add_columns}
	}
    } \
    -on_request {} \
    -on_submit {}

set report_p $report_p_preserved
ad_form \
    -name "remove_column_form" \
    -method "GET" \
    -export {format search_id query page page_size orderby report_p} \
    -has_submit "1" \
    -has_edit "1" \
    -form {
	{extended_columns:text(hidden),optional}
	{remove_column:text(select_with_optgroup)
	    {label ""}
	    {html {onChange "document.remove_column_form.submit();"}}
	    {options $remove_columns}
	}
    } \
    -on_request {} \
    -on_submit {}


set extended_columns $extended_columns_preserved
template::element::set_value add_column_form extended_columns $extended_columns
template::element::set_value remove_column_form extended_columns $extended_columns

