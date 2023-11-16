-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-21
-- CHANGE REASON: [CEMR-1692] API to manage Building/Floor/Department…V
CREATE OR REPLACE VIEW v_floors as 
SELECT f.id_floors, f.code_floors, f.image_plant, f.rank, f.flg_available
  FROM floors f;
-- CHANGE END: Kelsey Lai
