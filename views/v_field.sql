CREATE OR REPLACE view v_field AS 
SELECT id_field, code_field, id_field_type, flg_field_prof_inst, flg_available
  FROM field;