CREATE OR REPLACE VIEW V_EXAM_CAT_DCS AS 
SELECT id_exam_cat_dcs,
       id_exam_cat,
       id_dep_clin_serv
  FROM exam_cat_dcs;