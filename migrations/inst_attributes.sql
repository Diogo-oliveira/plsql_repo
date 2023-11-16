-- CHANGED BY: Vitor Sa
-- CHANGE DATE: 12/04/2018 09:41
-- CHANGE REASON: [EMR-2357] EMR-2357
UPDATE inst_attributes
   SET flg_street_type = id_street_type
 WHERE id_street_type IS NOT NULL;
 
-- CHANGE END: Vitor Sa