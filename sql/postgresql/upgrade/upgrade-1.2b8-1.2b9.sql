-- 
-- packages/contacts/sql/postgresql/upgrade/upgrade-1.2b7-1.2b8.sql
-- 
-- @author Matthew Geddert (openacs@geddert.com)
-- @creation-date 2006-03-31
-- @arch-tag: 
-- @cvs-id $Id$
--

alter table contact_search_extend_map drop constraint contact_search_extend_map_attribute_id_fk;
alter table contact_search_extend_map drop column attribute_id;
alter table contact_search_extend_map add column extend_column varchar(255);

-- if extensions based on attribute_id were saved they could not be upgraded to
-- the new extended_column system so we delete those dead entries here to clean
-- up the data.

delete from contact_search_extend_map where extend_id is null;
