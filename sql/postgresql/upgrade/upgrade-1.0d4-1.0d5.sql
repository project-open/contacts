-- 
-- packages/contacts/sql/postgresql/upgrade/upgrade-1.0d4-1.0d5.sql
-- 
-- @author Malte Sussdorff (sussdorff@sussdorff.de)
-- @creation-date 2005-07-28
-- @arch-tag: c6a87521-0c9d-45b8-8f3f-852d262c8af0
-- @cvs-id $Id$
--

alter table contact_message_items add column locale varchar(30);
insert into contact_message_types (message_type,pretty_name) values ('header','#contacts.Header#');
insert into contact_message_types (message_type,pretty_name) values ('footer','#contacts.Footer#');

drop view contact_messages;
create or replace view contact_messages as 
    select cmi.item_id, 
           cmi.owner_id,
           cmi.message_type,
	   cmi.locale,
           cr.title,
           cr.description,
           cr.content,
           cr.mime_type as content_format
      from contact_message_items cmi, cr_items ci, cr_revisions cr
     where cmi.item_id = cr.item_id
       and ci.publish_status not in ( 'expired' )
       and ci.live_revision = cr.revision_id
;