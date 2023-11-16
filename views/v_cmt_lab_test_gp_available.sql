CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_GP_AVAILABLE AS
SELECT DISTINCT desc_lab_test_group, desc_alias, id_cnt_lab_test_group, id_lab_test_group
  FROM (SELECT t.desc_translation desc_lab_test_group,
               a.id_content id_cnt_lab_test_group,
               a.id_analysis_group id_lab_test_group,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      alert.pk_lab_tests_utils.get_alias_code_translation(sys_context('ALERT_CONTEXT',
                                                                                                                      'ID_LANGUAGE'),
                                                                                                          profissional(0,
                                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                                   'ID_INSTITUTION'),
                                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                                   'ID_SOFTWARE')),
                                                                                                          'G',
                                                                                                          a.code_analysis_group,
                                                                                                          NULL))
                  FROM dual) desc_alias
          FROM analysis_group a
          JOIN v_cmt_translation_agp t
            ON t.code_translation = a.code_analysis_group
          JOIN alert.analysis_instit_soft ais
            ON ais.id_analysis_group = a.id_analysis_group
           AND ais.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ais.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND ais.flg_type = 'P'
           AND ais.flg_available = 'Y'
         WHERE a.flg_available = 'Y'
           AND a.id_content IS NOT NULL);

