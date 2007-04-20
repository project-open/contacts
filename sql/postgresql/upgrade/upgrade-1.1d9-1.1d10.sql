insert into contact_message_types (message_type,pretty_name) values ('oo_mailing','#contacts.oo_mailing#');
alter table contact_message_items add column spoiler varchar(500);
alter table contact_message_items add column ps varchar(500);
drop view contact_messages;
create view contact_messages as 
    select cmi.item_id, 
           cmi.owner_id,
           cmi.message_type,
	   cmi.locale,
           cmi.spoiler,
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

