CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_GP_CATALOGUE AS
SELECT DISTINCT desc_lab_test_group,
                desc_alias,
                id_cnt_lab_test_group,
                gender,
                age_min,
                age_max,
                rank,
                id_lab_test_group,
                create_time
  FROM (SELECT t.desc_translation desc_lab_test_group,
               a.id_content id_cnt_lab_test_group,
               a.id_analysis_group AS id_lab_test_group,
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
                  FROM dual) desc_alias,
               a.gender,
               a.age_min,
               a.age_max,
               a.rank,
               to_char(a.create_time, 'DD-MON-YYYY HH24:MI') AS create_time
          FROM analysis_group a
         INNER JOIN v_cmt_translation_agp t
            ON t.code_translation = a.code_analysis_group
         WHERE a.flg_available = 'Y'
           AND a.id_content IS NOT NULL);

