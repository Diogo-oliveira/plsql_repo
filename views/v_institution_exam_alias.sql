-- CHANGED BY: José Castro
-- CHANGE DATE: 14/12/2010 10:50
-- CHANGE REASON: ALERT-149001
CREATE OR REPLACE VIEW V_INSTITUTION_EXAM_ALIAS AS
  SELECT ea.id_exam_alias, ea.id_exam, ea.code_exam_alias, ea.id_institution
    FROM exam_alias ea
   WHERE ea.id_institution IS NOT NULL
     AND (ea.id_software IS NULL OR ea.id_software = 0)
     AND (ea.id_professional IS NULL OR ea.id_professional = 0)
     AND (ea.id_dep_clin_serv IS NULL OR ea.id_dep_clin_serv = 0);
-- CHANGED END: José Castro
