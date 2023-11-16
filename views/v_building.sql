-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-21
-- CHANGE REASON: [CEMR-1692] API to manage Building/Floor/Department…V
CREATE OR REPLACE VIEW v_building as 
SELECT b.id_building, b.code_building, b.flg_available, b.id_institution
  FROM building b;
-- CHANGE END: Kelsey Lai
