CREATE OR REPLACE VIEW v_speciality AS
SELECT s.id_speciality,
       s.code_speciality,
       s.flg_available,
       s.adw_last_update,
       s.id_content
  FROM speciality s;
