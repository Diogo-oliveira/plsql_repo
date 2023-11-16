CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST AS
SELECT desc_lab_test, id_cnt_lab_test
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_analysis)
                  FROM dual) desc_lab_test,
               a.id_content id_cnt_lab_test
          FROM alert.analysis a
         WHERE a.flg_available = 'Y')
 WHERE desc_lab_test IS NOT NULL
 ORDER BY 1;

