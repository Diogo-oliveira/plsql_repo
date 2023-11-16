CREATE OR REPLACE VIEW v_p1_speciality AS
SELECT id_speciality, code_speciality, flg_available, gender, age_min, age_max, id_parent
  FROM p1_speciality;