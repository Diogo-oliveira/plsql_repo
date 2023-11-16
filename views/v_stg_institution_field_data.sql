CREATE OR REPLACE VIEW v_stg_institution_field_data AS 
SELECT id_stg_institution, id_field, VALUE,id_stg_files,id_institution
  FROM stg_institution_field_data;