CREATE OR REPLACE view V_STG_PROFESSIONAL_FIELD_DATA AS 
SELECT id_stg_professional, id_field, VALUE,id_stg_files,id_institution
  FROM stg_professional_field_data;