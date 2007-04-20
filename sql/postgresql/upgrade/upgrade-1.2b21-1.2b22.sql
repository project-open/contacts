alter table contact_message_items add column oo_template varchar(500);
drop view contact_messages;
create view contact_messages as 
    select cmi.item_id, 
           cmi.owner_id,
           cmi.message_type,
	   cmi.locale,
           cmi.banner,
           cmi.ps,
	   cmi.oo_template,
           cr.title,
           cr.description,
           cr.content,
           cr.mime_type as content_format,
           ao.package_id
      from contact_message_items cmi, cr_items ci, cr_revisions cr, acs_objects ao
     where cmi.item_id = cr.item_id
       and ci.publish_status not in ( 'expired' )
       and ci.live_revision = cr.revision_id
       and ci.item_id = ao.object_id
;
