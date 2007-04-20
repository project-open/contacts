-- contacts/sql/postgresql/upgrade/upgrade-1.0d2-1.0d3.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2005-06-29
-- @cvs-id $Id$
--
--


-- we now use contact__folder_id() for the cr_folder and must replace the reference to contact_party_revision__folder_id()
create or replace function contact_party_revision__item_id (
        integer,                -- party_id
        timestamptz,            -- creation_date
        integer,                -- creation_user
        varchar                 -- creation_ip
) returns integer
as '
declare
        p_party_id              alias for $1;
        p_creation_date         alias for $2;
        p_creation_user         alias for $3;
        p_creation_ip           alias for $4;
        v_exists_p              boolean;
begin

        v_exists_p := ''1'' from cr_items where item_id = p_party_id;

        if v_exists_p is not true then
                insert into cr_items
                (item_id,parent_id,name,content_type)
                values
                (p_party_id,contact__folder_id(),p_party_id::varchar,''contact_party_revision'');
        end if;

        return p_party_id;
end;' language 'plpgsql';

drop function contact_party_revision__folder_id ();
create or replace function contact__folder_id () returns integer
as '
declare
        v_folder_id              integer;
begin

        v_folder_id := cf.folder_id from cr_items ci, cr_folders cf
                            where ci.item_id = cf.folder_id
                              and ci.parent_id = ''0''
                              and ci.name = ''contacts'';

        if v_folder_id is null then
                v_folder_id := content_folder__new (
                                  ''contacts'',
                                  ''Contacts'',
                                  NULL,
                                  ''0''
                );
        end if;

        return v_folder_id;
end;' language 'plpgsql';


create table contact_message_types (
	message_type             varchar(20)
                                 constraint contact_message_types_pk primary key,
        pretty_name              varchar(100)
                                 constraint contact_message_types_pretty_name_nn not null
);
insert into contact_message_types (message_type,pretty_name) values ('email','#contacts.Email#');
insert into contact_message_types (message_type,pretty_name) values ('letter','#contacts.Letter#');


create table contact_message_items (
	item_id                 integer
                                constraint contact_message_items_id_fk references cr_items(item_id)
                                constraint contact_message_items_id_pk primary key,
        owner_id                integer
                                constraint contact_message_items_owner_id_fk references acs_objects(object_id) on delete cascade
                                constraint contact_message_items_owner_id_nn not null,
        message_type            varchar(20)
                                constraint contact_message_items_message_type_fk references contact_message_types(message_type)
                                constraint contact_message_items_message_type_nn not null
);

select content_folder__register_content_type(contact__folder_id(),'content_revision','t');

create view contact_messages as 
    select cmi.item_id, 
           cmi.owner_id,
           cmi.message_type,
           cr.title,
           cr.description,
           cr.content,
           cr.mime_type as content_format
      from contact_message_items cmi, cr_items ci, cr_revisions cr
     where cmi.item_id = cr.item_id
       and ci.publish_status not in ( 'expired' )
       and ci.live_revision = cr.revision_id
;


create table contact_message_log (
        message_id              integer
                                constraint contact_message_log_message_id_pk primary key,
        message_type            varchar(20)
                                constraint contact_message_log_message_type_fk references contact_message_types(message_type)
                                constraint contact_message_log_message_type_nn not null,
        sender_id               integer
                                constraint contact_message_sender_id_fk references users(user_id)
                                constraint contact_message_sender_id_nn not null,
        recipient_id            integer
                                constraint contact_message_recipient_id_fk references parties(party_id)
                                constraint contact_message_recipient_id_nn not null,
        sent_date               timestamptz
                                constraint contact_message_sent_date_nn not null,
        title                   varchar(1000),
	description             text,
        content                 text
                                constraint contact_message_log_content_nn not null,
        content_format          varchar(200)
                                constraint contact_message_log_content_format_fk references cr_mime_types(mime_type)
                                constraint contact_message_log_content_format_nn not null
);


