ad_page_contract {
    page to import a csv file to the system (contacts)

    @author Nils Lohse (nils.lohse@cognovis.de)
    @creation-date 21 Nov 2006
} {
    upload_file:trim,optional
    {return_url ""}
    upload_file.tmpfile:tmpfile,optional
} -properties {
    context:onevalue
    instructions:onevalue
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

set context "[_ file-storage.Add_File]"

set options [contact::groups -output "ad_form"]
#ad_return_error test $options

ad_form -name file-import -action import-csv-2 -html { enctype multipart/form-data } -export { return_url } -form {
    {upload_file:file {label "[_ file-storage.Upload_a_file]"} {html "size 30"}}
    {group_ids:integer(checkbox),multiple,optional
	{label "[_ contacts.Groups]"}
	{options "$options"}
	{help_text "[_ contacts.cvs_groups_help]"}
    }
} 
    

set instructions "[_ contacts.lt_csv_import_instructions]"

ad_return_template
