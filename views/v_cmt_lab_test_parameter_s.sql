CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_PARAMETER_S AS
SELECT desc_lab_test_parameter, id_cnt_lab_test_parameter, id_lab_test_parameter
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      a.code_analysis_parameter)
                  FROM dual) desc_lab_test_parameter,
               a.id_content id_cnt_lab_test_parameter,
               a.id_analysis_parameter AS id_lab_test_parameter
          FROM alert.analysis_parameter a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER')) t
            ON t.code_translation = a.code_analysis_parameter
         WHERE a.flg_available = 'N')
 WHERE desc_lab_test_parameter IS NOT NULL
 ORDER BY 1;

