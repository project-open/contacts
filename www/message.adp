<master>
<property name="title">@title@</property>
<property name="context">@context@</property>
<property name="header_stuff">
    <link href="/resources/contacts/contacts.css" rel="stylesheet" type="text/css">
</property>
<property name="focus">comment_add.comment</property>

  <if @message_type@ eq "">
    <formtemplate id="message"></formtemplate>
  </if>
  <else>
    	<include 	
        	src=/packages/contacts/lib/@message_type@
        	return_url=@return_url;noquote@ 
	        party_ids=@party_ids@ 
	        file_ids=@file_ids@ 
		files_extend=@files_extend@
		item_id=@item_id@
	        signature_id=@signature_id@ 
	        recipients=@recipients;noquote@
	        footer_id=@footer_id@
	        header_id=@header_id@
	        folder_id=@folder_id@
		title=@title@
		cc=@cc@	
		bcc=@bcc@
		to=@to@
		context_id=@context_id@
		object_od=@object_id@
	        >
  </else>
