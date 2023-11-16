CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_S AS
SELECT desc_lab_test, id_cnt_lab_test
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_analysis)
                  FROM dual) desc_lab_test,
               a.id_content id_cnt_lab_test
          FROM alert.analysis a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'ANALYSIS.CODE_ANALYSIS')) t
            ON t.code_translation = a.code_analysis
         WHERE a.flg_available = 'N')
 WHERE desc_lab_test IS NOT NULL
 ORDER BY 1;

