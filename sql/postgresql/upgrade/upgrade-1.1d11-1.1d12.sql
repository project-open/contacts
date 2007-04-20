alter table contact_message_items add column banner varchar(500);
update contact_message_items set banner = spoiler;
alter table contact_message_items drop column spoiler cascade;
create view contact_messages as 
    select cmi.item_id, 
           cmi.owner_id,
           cmi.message_type,
	   cmi.locale,
           cmi.banner,
           cmi.ps,
           cr.title,
           cr.description,
           cr.content,
           cr.mime_type as content_format
      from contact_message_items cmi, cr_items ci, cr_revisions cr
     where cmi.item_id = cr.item_id
       and ci.publish_status not in ( 'expired' )
       and ci.live_revision = cr.revision_id
;
