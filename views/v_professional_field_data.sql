CREATE OR REPLACE view v_professional_field_data AS 
SELECT id_professional, id_field_market, VALUE, id_institution
  FROM professional_field_data;