CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_ST_CATALOGUE_S AS
SELECT "DESC_LAB_TEST","DESC_SAMPLE_TYPE","DESC_LAB_TEST_SAMPLE_TYPE","DESC_ALIAS","ID_CNT_LAB_TEST_SAMPLE_TYPE","ID_CNT_LAB_TEST","ID_CNT_SAMPLE_TYPE","GENDER","AGE_MIN","AGE_MAX","CREATE_TIME"
  FROM (SELECT DISTINCT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), code_analysis)
                           FROM dual) AS desc_lab_test,
                        (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               code_sample_type)
                           FROM dual) AS desc_sample_type,
                        (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               code_analysis_sample_type)
                           FROM dual) AS desc_lab_test_sample_type,
                        (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               code_ast_alias)
                           FROM dual) desc_alias,
                        id_cnt_lab_test_sample_type,
                        id_cnt_lab_test,
                        id_cnt_sample_type,
                        gender,
                        age_min,
                        age_max,
                        to_char(create_time, 'DD-MON-YYYY HH24:MI') AS create_time
          FROM (SELECT a.code_analysis,
                       c.code_sample_type,
                       b.code_analysis_sample_type,
                       asta.code_ast_alias,
                       b.id_content                id_cnt_lab_test_sample_type,
                       a.id_content                id_cnt_lab_test,
                       c.id_content                id_cnt_sample_type,
                       b.gender,
                       b.age_min,
                       b.age_max,
                       b.create_time
                  FROM alert.analysis_sample_type b
                  JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE')) t
                    ON t.code_translation = b.code_analysis_sample_type
                  JOIN alert.analysis a
                    ON b.id_analysis = a.id_analysis
                   AND a.flg_available = 'Y'
                  JOIN alert.sample_type c
                    ON c.id_sample_type = b.id_sample_type
                   AND c.flg_available = 'Y'
                  LEFT JOIN alert.analysis_sample_type_alias asta
                    ON asta.id_analysis = b.id_analysis
                   AND asta.id_sample_type = b.id_sample_type
                   AND asta.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND asta.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE b.flg_available = 'Y'
                   AND lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')) != 'all'
                   AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cnt314.') = 0
                   AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cntx.') = 0
                UNION
                SELECT a.code_analysis,
                       c.code_sample_type,
                       b.code_analysis_sample_type,
                       asta.code_ast_alias,
                       b.id_content                id_cnt_lab_test_sample_type,
                       a.id_content                id_cnt_lab_test,
                       c.id_content                id_cnt_sample_type,
                       b.gender,
                       b.age_min,
                       b.age_max,
                       b.create_time
                  FROM alert.analysis_sample_type b
                  JOIN alert.analysis a
                    ON b.id_analysis = a.id_analysis
                   AND a.flg_available = 'Y'
                  JOIN alert.sample_type c
                    ON c.id_sample_type = b.id_sample_type
                   AND c.flg_available = 'Y'
                  LEFT JOIN alert.analysis_sample_type_alias asta
                    ON asta.id_analysis = b.id_analysis
                   AND asta.id_sample_type = b.id_sample_type
                   AND asta.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND asta.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE b.flg_available = 'Y'
                   AND b.id_content = sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')
                UNION
                SELECT a.code_analysis,
                       c.code_sample_type,
                       b.code_analysis_sample_type,
                       asta.code_ast_alias,
                       b.id_content                id_cnt_lab_test_sample_type,
                       a.id_content                id_cnt_lab_test,
                       c.id_content                id_cnt_sample_type,
                       b.gender,
                       b.age_min,
                       b.age_max,
                       b.create_time
                  FROM alert.analysis_sample_type b
                  JOIN alert.analysis a
                    ON b.id_analysis = a.id_analysis
                   AND a.flg_available = 'Y'
                  JOIN alert.sample_type c
                    ON c.id_sample_type = b.id_sample_type
                   AND c.flg_available = 'Y'
                  LEFT JOIN alert.analysis_sample_type_alias asta
                    ON asta.id_analysis = b.id_analysis
                   AND asta.id_sample_type = b.id_sample_type
                   AND asta.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND asta.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE b.flg_available = 'Y'
                   AND lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')) = 'all'))
 WHERE desc_lab_test_sample_type IS NOT NULL
 ORDER BY 1;

