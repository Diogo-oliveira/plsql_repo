CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_GROUP_ASSOC AS
SELECT "DESC_LAB_TEST_GROUP",
       "ID_CNT_LAB_TEST_GROUP",
       "DESC_LAB_TEST_SAMPLE_TYPE",
       "ID_CNT_LAB_TEST_SAMPLE_TYPE",
       "RANK"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_analysis_group)
                  FROM dual) desc_lab_test_group,
               a.id_content id_cnt_lab_test_group,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      c.code_analysis_sample_type)
                  FROM dual) desc_lab_test_sample_type,
               c.id_content id_cnt_lab_test_sample_type,
               b.rank
          FROM analysis_group a
          JOIN analysis_agp b
            ON a.id_analysis_group = b.id_analysis_group
           AND b.flg_available = 'Y'
          JOIN analysis_sample_type c
            ON c.id_analysis = b.id_analysis
           AND c.id_sample_type = b.id_sample_type
           AND c.flg_available = 'Y'
          JOIN alert.analysis_instit_soft e
            ON e.id_analysis_group = a.id_analysis_group
           AND e.flg_available = 'Y'
           AND e.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND e.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
         WHERE a.flg_available = 'Y'
           AND (c.id_analysis, c.id_sample_type) IN
               (SELECT e.id_analysis, e.id_sample_type
                  FROM alert.analysis_instit_soft e
                 WHERE e.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND e.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND e.flg_available = 'Y')
           AND a.id_content IS NOT NULL
           AND a.flg_available = 'Y')
 WHERE desc_lab_test_group IS NOT NULL
   AND desc_lab_test_sample_type IS NOT NULL;

