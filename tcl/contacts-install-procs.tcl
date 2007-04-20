ad_library {

    Contacts install library

    Procedures that deal with installing, instantiating, mounting.

    @creation-date 2005-05-26
    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id$
}

namespace eval contacts::install {}


ad_proc -public contacts::install::package_install {
} {
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-04

    @return

    @error
} {

    # Register Relationships

    rel_types::new -table_name "contact_rels" -create_table_p "f" \
	"contact_rel" \
	"#contacts.Contact_Relationship#" \
	"#contacts.lt_Contact_Relationships#" \
	"party" \
	"0" \
	"" \
	"party" \
	"0" \
	""

    rel_types::create_role -role "organization" -pretty_name "Organization" -pretty_plural "Organizations"

    rel_types::new -table_name "organization_rels" -create_table_p "f" \
	"organization_rel" \
	"#contacts.lt_Organization_Relation#" \
	"#contacts.lt_Organization_Relation_1#" \
	"group" \
	"0" \
	"" \
	"organization" \
	"0" \
	""

    rel_types::create_role -role "employee" -pretty_name "Employee" -pretty_plural "Employees"
    rel_types::create_role -role "employer" -pretty_name "Employer" -pretty_plural "Employers"
    rel_types::new -table_name "contact_rel_employment" -create_table_p "t" -supertype "contact_rel" -role_one "employee" -role_two "employer" \
	"contact_rels_employment" \
	"#contacts.lt_Contact_Rel_Employmen#" \
	"#contacts.lt_Contact_Rels_Employme#" \
	"person" \
	"0" \
	"" \
	"organization" \
	"0" \
	""


    rel_types::create_role -role "spouse" -pretty_name "Spouse" -pretty_plural "Spouses"
    rel_types::new -table_name "contact_rel_spouse" -create_table_p "t" -supertype "contact_rel" -role_one "spouse" -role_two "spouse" \
	"contact_rels_spouse" \
	"#contacts.lt_Contact_Rel_Spouse#" \
	"#contacts.lt_Contact_Rels_Spous#" \
	"person" \
	"0" \
	"" \
	"person" \
	"0" \
	""

    # Creation of contact_complaint_track table
    content::type::new -content_type "contact_complaint" \
	-pretty_name "Contact Complaint" \
	-pretty_plural "Contact Complaints" \
	-table_name "contact_complaint_track" \
	-id_column "complaint_id"
    
    # now set up the attributes that by default we need for the complaints
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "customer_id" \
	-datatype "integer" \
	-pretty_name "Customer ID" \
	-sort_order 1 \
	-column_spec "integer constraint contact_complaint_track_customer_fk
                                  references parties(party_id) on delete cascade"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "turnover" \
	-datatype "money" \
	-pretty_name "Turnover" \
	-sort_order 2 \
	-column_spec "float"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "percent" \
	-datatype "integer" \
	-pretty_name "Percent" \
	-sort_order 3 \
	-column_spec "integer"

    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "supplier_id" \
	-datatype "integer" \
	-pretty_name "Supplier ID" \
	-sort_order 4 \
	-column_spec "integer"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "paid" \
	-datatype "money" \
	-pretty_name "Paid" \
	-sort_order 5 \
	-column_spec "float"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "complaint_object_id" \
	-datatype "integer" \
	-pretty_name "Complaint Object ID" \
	-sort_order 6 \
	-column_spec "integer constraint contact_complaint_track_complaint_object_id_fk 
                                  references acs_objects(object_id) on delete cascade"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "state" \
	-datatype "string" \
	-pretty_name "State" \
	-sort_order 7 \
	-column_spec "varchar(7) constraint cct_state_ck
                                  check (state in ('valid','invalid','open'))"

    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "employee_id" \
	-datatype "integer" \
	-pretty_name "Employee ID" \
	-sort_order 8 \
	-column_spec "integer constraint contact_complaint_track_employee_fk
                                  references parties(party_id) on delete cascade"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "refund_amount" \
	-datatype "money" \
	-pretty_name "Refund Amount" \
	-sort_order 9 \
	-column_spec "float"
    
}

ad_proc -public contacts::install::package_instantiate {
    {-package_id:required}
} {

    # We want to instantiate the contacts package so that registered

    # users have some attributes mapped by default. This could be extended in custom packages.

    # set default_group [contacts::default_group -package_id $package_id]
    # we first need to establish a default group for this instance.

    set default_group [application_group::new -package_id $package_id -group_name "\#contacts.All_Contacts\#"]

    # if the user chooses to set the parameter UseSubsiteAsDefaultGroup
    # these attributes will not be in the form. We will add all attributes
    # to both the instance application group as well as the subsite application
    # group

    # node_id is not set yet in the install process, we will assume that 

#    set node_id [db_string get_it { select node_id from site_nodes where object_id = :package_id }]

    # getting the the context_id of the parent package might be a cleaner way of doing this? if yes we should change it.
    set node_id [db_string get_it { select node_id from site_nodes where object_id is null order by node_id desc limit 1 }]
    set subsite_id [site_node::closest_ancestor_package -node_id $node_id -package_key "acs-subsite"]
    set subsite_default_group [application_group::group_id_from_package_id -no_complain -package_id $subsite_id]


    ams::widgets_init
    set list_id [ams::list::new \
		     -package_key "contacts" \
		     -object_type "person" \
		     -list_name "${package_id}__$default_group" \
		     -pretty_name "#contacts.lt_Person_-_Registered_U#" \
		     -description "" \
		     -description_mime_type ""]
    set subsite_list_id [ams::list::new \
		     -package_key "contacts" \
		     -object_type "person" \
		     -list_name "${package_id}__$subsite_default_group" \
		     -pretty_name "#contacts.lt_Person_-_Registered_U#" \
		     -description "" \
		     -description_mime_type ""]

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "first_names" \
			  -datatype "string" \
			  -pretty_name "First Name(s)" \
			  -pretty_plural "First Names" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "0" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "type_specific" \
			  -static_p "f" \
			  -if_does_not_exist]

    ams::attribute::new -attribute_id $attribute_id -widget "textbox" -dynamic_p "f"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "1" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $subsite_list_id \
	-attribute_id $attribute_id \
	-sort_order "1" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "last_name" \
			  -datatype "string" \
			  -pretty_name "Last Name" \
			  -pretty_plural "Last Names" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "0" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "type_specific" \
			  -static_p "f" \
			  -if_does_not_exist]

    ams::attribute::new -attribute_id $attribute_id -widget "textbox" -dynamic_p "f"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "2" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $subsite_list_id \
	-attribute_id $attribute_id \
	-sort_order "2" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "party" \
			  -attribute_name "email" \
			  -datatype "string" \
			  -pretty_name "E-Mail" \
			  -pretty_plural "E-Mails" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "0" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "type_specific" \
			  -static_p "f" \
			  -if_does_not_exist]

    ams::attribute::new -attribute_id $attribute_id -widget "email" -dynamic_p "f"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "3" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $subsite_list_id \
	-attribute_id $attribute_id \
	-sort_order "3" \
	-required_p "f" \
	-section_heading ""

    # ORGANIZATIONS

    set list_id [ams::list::new \
		     -package_key "contacts" \
		     -object_type "organization" \
		     -list_name "${package_id}__$default_group" \
		     -pretty_name "Organization - Registered Users" \
		     -description "" \
		     -description_mime_type ""]

    set subsite_list_id [ams::list::new \
		     -package_key "contacts" \
		     -object_type "organization" \
		     -list_name "${package_id}__$subsite_default_group" \
		     -pretty_name "Organization - Registered Users" \
		     -description "" \
		     -description_mime_type ""]

    set attribute_id [attribute::new \
			  -object_type "organization" \
			  -attribute_name "name" \
			  -datatype "string" \
			  -pretty_name "Organization Name" \
			  -pretty_plural "Organization Names" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    ams::attribute::new -attribute_id $attribute_id -widget "textbox" -dynamic_p "t"

    ams::list::attribute::map \
 	-list_id $list_id \
 	-attribute_id $attribute_id \
 	-sort_order "1" \
 	-required_p "f" \
 	-section_heading ""

    ams::list::attribute::map \
 	-list_id $subsite_list_id \
 	-attribute_id $attribute_id \
 	-sort_order "1" \
 	-required_p "f" \
 	-section_heading ""

    # Make the registered users group mapped by default

    contacts::insert_map -group_id "$default_group" -default_p "t" -package_id $package_id

    # Callback for after instantiate
    callback contacts::package_instantiate -package_id $package_id
}

ad_proc -public contacts::install::package_mount {
    -package_id
    -node_id
} {
    
    Actions to be executed after mounting the contacts package

    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-04

    @return

    @error
} {
    contacts::populate::crm -package_id $package_id
}

ad_proc -public contacts::insert_map {
    {-group_id:required}
    {-default_p:required}
    {-package_id:required}
} {
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-03

    @param group_id

    @param default_p

    @param package_id

    @return

    @error
} {
    db_dml insert_map {
        insert into contact_groups
        (group_id,default_p,package_id)
        values
        (:group_id,:default_p,:package_id)}
}

ad_proc -public ::install::xml::action::contacts_pop_crm {
    node
} { 
    Procedure to register the populate crm for the install.xml
} {
    set url [apm_required_attribute_value $node url]
    array set sn_array [site_node::get -url $url]
    contacts::populate::crm -package_id $sn_array(object_id)
}


ad_proc -public contacts::install::package_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-10-05
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
	    1.0d18 1.0d19 {

		content::type::new -content_type "contact_complaint" \
		    -pretty_name "Contact Complaint" \
		    -pretty_plural "Contact Complaints" \
		    -table_name "contact_complaint_track" \
		    -id_column "complaint_id"
		
		# now set up the attributes that by default we need for the complaints
		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "customer_id" \
		    -datatype "integer" \
		    -pretty_name "Customer ID" \
		    -sort_order 1 \
		    -column_spec "integer constraint contact_complaint_track_customer_fk
                                  references parties(party_id) on delete cascade"
		
		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "turnover" \
		    -datatype "money" \
		    -pretty_name "Turnover" \
		    -sort_order 2 \
		    -column_spec "float"

		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "percent" \
		    -datatype "integer" \
		    -pretty_name "Percent" \
		    -sort_order 3 \
		    -column_spec "integer"

		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "supplier_id" \
		    -datatype "integer" \
		    -pretty_name "Supplier ID" \
		    -sort_order 4 \
		    -column_spec "integer"
		
		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "paid" \
		    -datatype "money" \
		    -pretty_name "Paid" \
		    -sort_order 5 \
		    -column_spec "float"

		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "complaint_object_id" \
		    -datatype "integer" \
		    -pretty_name "Complaint Object ID" \
		    -sort_order 6 \
		    -column_spec "integer constraint contact_complaint_track_complaint_object_id_fk 
                                  references acs_objects(object_id) on delete cascade"
		
		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "state" \
		    -datatype "string" \
		    -pretty_name "State" \
		    -sort_order 7 \
		    -column_spec "varchar(7) constraint cct_state_ck
                                  check (state in ('valid','invalid','open'))"
		
		# Now we need to copy all information on contact_complaint_tracking table (the one we are taking out)
		# into the new one called contact_complaint_track with the new fields. This is simple since
		# all the collumns have the same datatype, just changed some names.
		
		db_dml insert_data {
		    insert into 
		    contact_complaint_track 
		    (complaint_id,customer_id,turnover,percent,supplier_id,paid,complaint_object_id,state) 
		    select * from contact_complaint_tracking
		}
		
		# Now we just delete the table contact_complaint_tracking
		db_dml drop_table { drop table contact_complaint_tracking } 
	    }
	    
	    1.0d21 1.0d22 {

		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "employee_id" \
		    -datatype "integer" \
		    -pretty_name "Employee ID" \
		    -sort_order 8 \
		    -column_spec "integer constraint contact_complaint_track_employee_fk
                                  references parties(party_id) on delete cascade"

		content::type::attribute::new \
		    -content_type "contact_complaint" \
		    -attribute_name "refund_amount" \
		    -datatype "money" \
		    -pretty_name "Refund" \
		    -sort_order 9 \
		    -column_spec "float"

	    }


	    1.2b3 1.2b4 {

		ns_log notice "Running contacts::install::package_upgrade upgrade from 1.2b3 to 1.2b4"

		# We should only have one contacts instance since in 1.2b3 contacts
                # was singleton. We need the package_id of that contacts instance

		set package_id [db_string get_package_id { select package_id from apm_packages where package_key = 'contacts' } -default {}]
		if { $package_id eq "" } {
		    ns_log notice "Although contacts was installed there are no instances of contacts 1.2b3 so we do not need to do anything."
		} else {
		    ns_log notice "The package_id of the singleton contacts 1.2b3 instance is: $package_id"

		    # in 1.2b3 contacts was dependent on the registered users group "-2"
		    # now that contacts can use application groups we need to make sure
                    # one exists for the contacts instance that already exists. There
                    # was one developmental version prior to 1.2b3 that had application
                    # groups so it might already exist.

		    set contacts_application_group_id [application_group::group_id_from_package_id -no_complain -package_id $package_id]
		    if { $contacts_application_group_id ne "" } {
			ns_log notice "An application group (${contacts_application_group_id}) already exists for contacts instance ${package_id}."
		    } else {
			# We are not going to copy all the attributes to this
			# application groups list. Since we we do not want to
			# make assumptions about how a site should be configured
			set contacts_application_group_id [application_group::new -package_id $package_id -group_name "\#contacts.All_Contacts\#"]
			ns_log notice "An application group (${contacts_application_group_id}) was created for contacts instance ${package_id}."
		    }

		    # Since contacts prior to 1.2b4 was singleton and it was set to
		    # use the '-2' group we are going to set the parameter
		    # 'UseSubsiteAsDefaultGroup' to '1'. This will mean that contacts
		    # will use the '-2' group if it was mounted on the root subsite
		    # since '-2' is the application group for that subsite.

		    parameter::set_value -package_id $package_id -parameter "UseSubsiteAsDefaultGroup" -value "1"
                    ns_log notice "The parameter 'UseSubsiteAsDefaultGroup' was set to a value of '1' (the default is '0') for package_id '$package_id'. Although contacts now allows the use of application groups specific to that contacts instance (which is the default) and is not dependent on the 'registered users' group, versions of contacts prior to 1.2b4 used the '-2' application group of the root subsite as their default group. This parameter setting will mean that contacts instances mounted directly on the root subsite will continue to use the '-2' group as the default, which means no change in behavior of the contacts instance because of the ugprade from 1.2b3 to 1.2b4."

                    # If contacts was not mounted on the root subsite then your
                    # site will likely need to run a custom contact::default_group_not_cached
                    # proc that returns this packages default group.

		    set contacts_node_id [site_node::get_node_id_from_object_id -object_id ${package_id}]
		    set subsite_package_id [site_node::closest_ancestor_package -node_id $contacts_node_id -package_key "acs-subsite"]
		    set subsite_application_group_id [application_group::group_id_from_package_id -no_complain -package_id $subsite_package_id]

		    if { $subsite_application_group_id ne "-2" } {
			error "The upgrade from contacts 1.2b3 to 1.2b4 removes contacts dependence on the registered users group '-2'. It is set to automatically use the nearest subsites application group. Unfortunately since your contacts instance is not mounted directly on the root subsite (i.e. its not mounted at a url similar to /contacts/) this application group is '$subsite_application_group_id'. You either need to manually move all of your contacts and ams::lists associated with the '-2' group to this application group (note the ams::list::copy will come in hand for this) or you may run a custom contacts::default_group_not_cached proc that will return the appropriate_id for your install and keep its functionality for any new contacts instance you create. This proc that corrects your setup should not be part of the offical contacts release since its a hack that is now site specific. Sorry for the significant inconvenience. This was what happens when you live on the bleeding edge of developmental versions of software :("
		    }

		}

	    }

	}

}

