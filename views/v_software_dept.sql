-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-21
-- CHANGE REASON: [CEMR-1692] API to manage Building/Floor/Department…V
CREATE OR REPLACE VIEW v_software_dept as 
SELECT sd.id_software_dept,
       sd.id_software,
       sd.id_dept
  FROM software_dept sd
-- CHANGE END: Kelsey Lai
