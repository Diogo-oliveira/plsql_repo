CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_EXAM_CAT_CATALOGUE AS
SELECT DISTINCT desc_exam_cat, id_cnt_exam_cat, rank, id_exam_cat
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), ec.code_exam_cat)
                  FROM dual) desc_exam_cat,
               ec.id_content id_cnt_exam_cat,
               rank,
               id_exam_cat AS id_exam_cat
          FROM alert.exam_cat ec
         WHERE ec.flg_lab = 'N'
           AND ec.flg_available = 'Y')
 WHERE desc_exam_cat IS NOT NULL
 ORDER BY 1;

