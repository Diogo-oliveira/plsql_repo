-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
CREATE OR REPLACE VIEW V_ORIGIN_SOFT_INST AS
SELECT osi.id_origin, 
       osi.id_institution, 
       osi.id_software, 
       osi.id_origin_soft_inst, 
       osi.flg_available
  FROM origin_soft_inst osi;
  
-- CHANGE END: Telmo Castro