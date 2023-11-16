-- CHANGED BY: Andre Silva
-- CHANGE DATE: 26-06-2018
-- CHANGE REASON: CEMR-1753
CREATE OR REPLACE VIEW V_EXAM_CAT AS
SELECT ec.id_exam_cat, 
       ec.flg_available, 
       ec.flg_lab, 
       ec.id_content, 
       ec.code_exam_cat,
	   ec.flg_interface,
       ec.rank,
       ec.parent_id
  FROM exam_cat ec;
  
-- CHANGE END: Andre Silva