ALTER TABLE contact_search_extend_map DROP CONSTRAINT contact_search_extend_map_pk;

ALTER TABLE contact_search_extend_map 
ALTER COLUMN extend_id DROP not null;


ALTER TABLE contact_search_extend_map ADD COLUMN attribute_id integer;

ALTER TABLE contact_search_extend_map 
ADD CONSTRAINT contact_search_extend_map_attribute_id_fk 
FOREIGN KEY (attribute_id) 
REFERENCES acs_attributes(attribute_id);
