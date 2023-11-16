-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 01/03/2012 10:00
-- CHANGE REASON: [ALERT-220450 ] 
CREATE OR REPLACE VIEW v_precaution AS 
SELECT id_precaution, code_precaution, flg_available, id_content
  FROM precaution;
-- CHANGE END: Sérgio Santos