-- CHANGED BY: Teresa Coutinho
-- CHANGE DATE: 2012-04-04
-- CHANGE REASON: ALERT-224969 
CREATE OR REPLACE VIEW V_UNIT_MEASURE as
SELECT um.id_unit_measure, 
      um.code_unit_measure, 
      um.id_unit_measure_type, 
      um.internal_name, 
      um.enumerated, 
      um.flg_available, 
      um.adw_last_update, 
      um.code_unit_measure_abrv, 
      um.id_content
FROM unit_measure um;
--CHANGE END
