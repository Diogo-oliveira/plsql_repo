CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_CATALOGUE_S AS
SELECT DISTINCT desc_lab_test, desc_alias, id_cnt_lab_test
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_analysis)
                  FROM dual) desc_lab_test,
               a.id_content id_cnt_lab_test,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      alert.pk_lab_tests_utils.get_alias_code_translation(sys_context('ALERT_CONTEXT',
                                                                                                                      'ID_LANGUAGE'),
                                                                                                          profissional(0,
                                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                                   'ID_INSTITUTION'),
                                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                                   'ID_SOFTWARE')),
                                                                                                          'A',
                                                                                                          a.code_analysis,
                                                                                                          NULL))
                  FROM dual) desc_alias
          FROM alert.analysis a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'ANALYSIS.CODE_ANALYSIS')) t
            ON t.code_translation = a.code_analysis
         WHERE a.flg_available = 'N')
 WHERE desc_lab_test IS NOT NULL
 ORDER BY 1;

