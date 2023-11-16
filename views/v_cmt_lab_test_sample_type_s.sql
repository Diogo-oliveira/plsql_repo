CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_SAMPLE_TYPE_S AS
WITH tmp AS
 (SELECT d.id_analysis, d.id_sample_type
    FROM alert.analysis_instit_soft d
   WHERE d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
     AND d.flg_type = 'P'
     AND d.id_analysis_group IS NULL
     AND d.flg_available = 'Y'
     AND d.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
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
       "FLG_FILL_TYPE",
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
               NULL AS flg_mov_pat,
               NULL AS flg_first_result,
               NULL AS flg_mov_recipient,
               NULL AS flg_harvest,
               NULL AS flg_fill_type,
               NULL AS flg_execute,
               NULL AS flg_justify,
               NULL AS flg_interface,
               NULL AS flg_duplicate_warn,
               NULL AS desc_exam_cat,
               NULL AS id_cnt_exam_cat,
               alert.pk_lab_tests_utils.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              profissional(0,
                                                                           sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                           0),
                                                              'A',
                                                              'ANALYSIS.CODE_ANALYSIS.' || a.id_analysis,
                                                              'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || c.id_sample_type,
                                                              NULL) desc_alias,
               (SELECT val
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      profissional(0,
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_INSTITUTION'),
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_SOFTWARE')),
                                                                      'ANALYSIS_REQ_DET.FLG_URGENCY',
                                                                      NULL))
                 WHERE rownum = 1) flg_priority,
               bbb.id_analysis
          FROM alert.analysis a
         INNER JOIN alert.analysis_sample_type b
            ON b.id_analysis = a.id_analysis
         INNER JOIN alert.sample_type c
            ON c.id_sample_type = b.id_sample_type
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE')) t
            ON t.code_translation = b.code_analysis_sample_type
          LEFT JOIN tmp bbb
            ON bbb.id_analysis = b.id_analysis
           AND bbb.id_sample_type = b.id_sample_type
         WHERE a.flg_available = 'Y'
           AND b.flg_available = 'Y'
           AND c.flg_available = 'Y'
           AND bbb.id_analysis IS NULL)
 WHERE desc_lab_test IS NOT NULL
   AND desc_sample_type IS NOT NULL;

