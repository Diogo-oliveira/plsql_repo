CREATE OR REPLACE view v_institution_field_data AS 
SELECT id_institution, id_field_market, VALUE
  FROM institution_field_data;