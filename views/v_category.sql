-- CHANGED BY: José Castro
-- CHANGE DATE: 31/05/2010 10:10
-- CHANGE REASON: ALERT-101292
CREATE OR REPLACE VIEW V_CATEGORY AS
SELECT id_category,
       code_category,
       flg_available,
       adw_last_update,
       flg_type,
       flg_clinical,
       flg_prof
       
  FROM category c;
-- CHANGE END: José Castro
