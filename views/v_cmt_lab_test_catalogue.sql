CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_CATALOGUE AS
SELECT DISTINCT desc_lab_test, desc_alias, id_cnt_lab_test
  FROM (SELECT t.desc_translation desc_lab_test,
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
          FROM analysis a
          JOIN v_cmt_translation_analysis t
            ON t.code_translation = a.code_analysis
         WHERE a.flg_available = 'Y')
 WHERE desc_lab_test IS NOT NULL
 ORDER BY 1;

