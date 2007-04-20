ALTER TABLE contact_extend_options ADD COLUMN aggregated_p char;
ALTER TABLE contact_extend_options ALTER COLUMN aggregated_p SET DEFAULT 'f';
ALTER TABLE contact_extend_options ADD CONSTRAINT check_aggregated_p CHECK (aggregated_p in ('t','f'));



