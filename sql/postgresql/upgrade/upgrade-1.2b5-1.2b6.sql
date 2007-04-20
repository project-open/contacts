-- 
-- packages/contacts/sql/postgresql/upgrade/upgrade-1.2b5-1.2b6.sql
-- 
-- @author Matthew Geddert (openacs@geddert.com)
-- @creation-date 2006-03-12
-- @arch-tag: 
-- @cvs-id $Id$
--

create table contact_deleted_history (
        party_id                integer
                                constraint contact_deleted_history_party_id_fk references parties(party_id) on delete cascade
                                constraint contact_deleted_history_party_id_nn not null,
        object_id               integer
                                constraint contact_deleted_history_object_id_fk references acs_objects(object_id) on delete cascade
                                constraint contact_deleted_history_object_id_nn not null,
        deleted_by              integer
                                constraint contact_deleted_history_deleted_by_fk references users(user_id) on delete cascade
                                constraint contact_deleted_history_deleted_by_nn not null,
        deleted_date            timestamptz default now()
                                constraint contact_deleted_history_deleted_date not null,
        unique(party_id,object_id)
);

