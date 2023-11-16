CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_CAT AS
SELECT "DESC_LAB_TEST_CAT", "ID_CNT_LAB_TEST_CAT", "RANK", "ID_LAB_TEST_CAT"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), ec.code_exam_cat)
                  FROM dual) desc_lab_test_cat,
               ec.id_content id_cnt_lab_test_cat,
               rank,
               id_exam_cat AS id_lab_test_cat
          FROM alert.exam_cat ec
         WHERE ec.flg_lab = 'Y'
           AND ec.flg_available = 'Y')
 WHERE desc_lab_test_cat IS NOT NULL
 ORDER BY 1;

