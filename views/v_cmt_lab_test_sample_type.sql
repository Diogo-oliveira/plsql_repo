CREATE OR REPLACE VIEW V_CMT_LAB_TEST_SAMPLE_TYPE AS
SELECT "DESC_LAB_TEST",
       "DESC_SAMPLE_TYPE",
       "ID_CNT_LAB_TEST_SAMPLE_TYPE",
       "ID_CNT_LAB_TEST",
       "ID_CNT_SAMPLE_TYPE",
       "GENDER",
       "AGE_MIN",
       "AGE_MAX",
       "FLG_MOV_PAT",
       "FLG_FIRST_RESULT",
       "FLG_MOV_RECIPIENT",
       "FLG_HARVEST",
       "FLG_EXECUTE",
       "FLG_JUSTIFY",
       "FLG_INTERFACE",
       "FLG_DUPLICATE_WARN",
       "DESC_EXAM_CAT",
       "ID_CNT_EXAM_CAT",
       "FLG_PRIORITY",
       "DESC_ALIAS"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_analysis)
                  FROM dual) desc_lab_test,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), c.code_sample_type)
                  FROM dual) desc_sample_type,
               b.id_content id_cnt_lab_test_sample_type,
               a.id_content id_cnt_lab_test,
               c.id_content id_cnt_sample_type,
               b.gender,
               b.age_min,
               b.age_max,
               d.flg_mov_pat,
               d.flg_first_result,
               d.flg_mov_recipient,
               d.flg_harvest,
               d.flg_execute,
               d.flg_justify,
               d.flg_interface,
               d.flg_duplicate_warn,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_exam_cat)
                  FROM dual) desc_exam_cat,
               e.id_content id_cnt_exam_cat,
               (SELECT alert.pk_lab_tests_utils.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      profissional(0,
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_INSTITUTION'),
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_SOFTWARE')),
                                                                      'A',
                                                                      'ANALYSIS.CODE_ANALYSIS.' || a.id_analysis,
                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || c.id_sample_type,
                                                                      NULL)
                  FROM dual) desc_alias,
               (SELECT nvl(d.flg_priority,
                           (SELECT val
                              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(sys_context('ALERT_CONTEXT',
                                                                                              'ID_LANGUAGE'),
                                                                                  profissional(0,
                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                           'ID_INSTITUTION'),
                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                           'ID_SOFTWARE')),
                                                                                  'ANALYSIS_REQ_DET.FLG_URGENCY',
                                                                                  NULL))
                             WHERE rownum = 1))
                  FROM dual) flg_priority
          FROM alert.analysis a
          JOIN alert.analysis_sample_type b
            ON b.id_analysis = a.id_analysis
          JOIN alert.sample_type c
            ON c.id_sample_type = b.id_sample_type
          JOIN alert.analysis_instit_soft d
            ON d.id_analysis = b.id_analysis
           AND d.id_sample_type = b.id_sample_type
          JOIN alert.exam_cat e
            ON e.id_exam_cat = d.id_exam_cat
         WHERE d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND d.flg_type = 'P'
           AND d.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND a.flg_available = 'Y'
           AND b.flg_available = 'Y'
           AND c.flg_available = 'Y'
           AND d.flg_available = 'Y'
           AND e.flg_available = 'Y'
           AND e.flg_lab = 'Y'
           AND d.id_analysis_group IS NULL)
 WHERE desc_lab_test IS NOT NULL
   AND desc_sample_type IS NOT NULL
   AND desc_exam_cat IS NOT NULL;
