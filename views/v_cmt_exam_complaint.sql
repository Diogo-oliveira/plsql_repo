CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_EXAM_COMPLAINT AS
SELECT "DESC_EXAM_CAT",
       "ID_CNT_EXAM_CAT",
       "DESC_IMG_EXAM",
       "ID_CNT_IMG_EXAM",
       "DESC_COMPLAINT",
       "ID_COMPLAINT",
       "ID_CNT_COMPLAINT",
       "FLG_GENDER",
       "AGE_MAX",
       "AGE_MIN"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), ecat.code_exam_cat)
                  FROM dual) desc_exam_cat,
               ecat.id_content id_cnt_exam_cat,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_exam)
                  FROM dual) desc_img_exam,
               e.id_content id_cnt_img_exam,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_complaint)
                  FROM dual) desc_complaint,
               a.id_complaint,
               a.id_content id_cnt_complaint,
               a.flg_gender,
               a.age_max,
               a.age_min
          FROM complaint a
          JOIN alert.exam_complaint ec
            ON ec.id_complaint = a.id_complaint
          JOIN alert.exam e
            ON e.id_exam = ec.id_exam
          JOIN alert.exam_cat ecat
            ON ecat.id_exam_cat = e.id_exam_cat
         WHERE e.flg_type = 'I'
           AND EXISTS (SELECT b.id_context
                  FROM alert.doc_template_context b
                 WHERE b.flg_type IN ('CT', 'C')
                   AND b.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND b.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')))
 WHERE desc_exam_cat IS NOT NULL
   AND desc_img_exam IS NOT NULL
   AND desc_complaint IS NOT NULL
 ORDER BY 1, 3, 5 ASC;

