CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_ST_AVAILABLE_S AS
WITH tmp AS
 (SELECT *
    FROM (SELECT /*+ MATERIALIZED */
          DISTINCT id_cnt_lab_test_sample_type,
                   (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                          a.code_analysis_sample_type)
                      FROM dual) AS desc_translation,
                   (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), asta.code_ast_alias)
                      FROM dual) AS desc_alias
            FROM (SELECT id_cnt_lab_test_sample_type, code_analysis_sample_type, id_analysis, id_sample_type
                    FROM (SELECT b.id_content AS id_cnt_lab_test_sample_type,
                                 b.code_analysis_sample_type,
                                 b.id_analysis,
                                 b.id_sample_type
                            FROM analysis_sample_type b
                            JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE')) t
                              ON t.code_translation = b.code_analysis_sample_type
                            JOIN analysis a
                              ON b.id_analysis = a.id_analysis
                             AND a.flg_available = 'Y'
                            JOIN sample_type c
                              ON c.id_sample_type = b.id_sample_type
                             AND c.flg_available = 'Y'
                           WHERE b.flg_available = 'Y'
                             AND lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')) != 'all'
                             AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cnt314.') = 0
                             AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cntx.') = 0)
                  UNION
                  SELECT id_cnt_lab_test_sample_type, code_analysis_sample_type, id_analysis, id_sample_type
                    FROM (SELECT b.id_content AS id_cnt_lab_test_sample_type,
                                 b.code_analysis_sample_type,
                                 b.id_analysis,
                                 b.id_sample_type
                            FROM analysis_sample_type b
                            JOIN analysis a
                              ON b.id_analysis = a.id_analysis
                             AND a.flg_available = 'Y'
                            JOIN sample_type c
                              ON c.id_sample_type = b.id_sample_type
                             AND c.flg_available = 'Y'
                           WHERE b.flg_available = 'Y'
                             AND 'all' = lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')))
                  UNION
                  SELECT id_cnt_lab_test_sample_type, code_analysis_sample_type, id_analysis, id_sample_type
                    FROM (SELECT b.id_content AS id_cnt_lab_test_sample_type,
                                 b.code_analysis_sample_type,
                                 b.id_analysis,
                                 b.id_sample_type
                            FROM analysis_sample_type b
                            JOIN analysis a
                              ON b.id_analysis = a.id_analysis
                             AND a.flg_available = 'Y'
                            JOIN sample_type c
                              ON c.id_sample_type = b.id_sample_type
                             AND c.flg_available = 'Y'
                           WHERE b.flg_available = 'Y'
                             AND b.id_content = sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'))
                  MINUS
                  SELECT id_cnt_lab_test_sample_type, code_analysis_sample_type, id_analysis, id_sample_type
                    FROM (SELECT b.id_content id_cnt_lab_test_sample_type,
                                 b.code_analysis_sample_type,
                                 b.id_analysis,
                                 b.id_sample_type
                            FROM analysis_sample_type b
                            JOIN analysis a
                              ON b.id_analysis = a.id_analysis
                             AND a.flg_available = 'Y'
                            JOIN sample_type c
                              ON c.id_sample_type = b.id_sample_type
                             AND c.flg_available = 'Y'
                            JOIN analysis_instit_soft d
                              ON d.id_analysis = b.id_analysis
                             AND d.id_sample_type = b.id_sample_type
                             AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                             AND d.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                             AND d.flg_type = 'P'
                             AND d.flg_available = 'Y'
                             AND d.id_analysis_group IS NULL
                            JOIN analysis_instit_recipient air
                              ON d.id_analysis_instit_soft = air.id_analysis_instit_soft
                             AND air.flg_default = 'Y'
                            JOIN sample_recipient sr
                              ON air.id_sample_recipient = sr.id_sample_recipient
                             AND sr.flg_available = 'Y'
                            JOIN exam_cat e
                              ON e.id_exam_cat = d.id_exam_cat
                             AND e.flg_available = 'Y'
                            JOIN analysis_room art
                              ON b.id_analysis = art.id_analysis
                             AND b.id_sample_type = art.id_sample_type
                             AND d.id_institution = art.id_institution
                             AND art.flg_default = 'Y'
                             AND art.flg_type = 'T'
                            JOIN analysis_room arm
                              ON b.id_analysis = arm.id_analysis
                             AND b.id_sample_type = arm.id_sample_type
                             AND d.id_institution = arm.id_institution
                             AND arm.flg_default = 'Y'
                             AND arm.flg_type = 'M'
                            JOIN analysis_param ap
                              ON ap.id_analysis = d.id_analysis
                             AND ap.id_sample_type = d.id_sample_type
                             AND d.id_institution = ap.id_institution
                             AND d.id_software = ap.id_software
                             AND ap.flg_available = 'Y'
                            JOIN analysis_parameter app
                              ON app.id_analysis_parameter = ap.id_analysis_parameter
                             AND app.flg_available = 'Y'
                           WHERE b.flg_available = 'Y')) a
            LEFT JOIN analysis_sample_type_alias asta
              ON asta.id_analysis = a.id_analysis
             AND asta.id_sample_type = a.id_sample_type
             AND asta.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
             AND asta.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
   WHERE desc_translation IS NOT NULL)
SELECT DISTINCT desc_lab_test_sample_type,
                desc_alias,
                id_cnt_lab_test_sample_type,
                desc_lab_test_cat,
                id_cnt_lab_test_cat,
                desc_sample_recipient,
                id_cnt_sample_recipient,
                desc_room_execution,
                id_room_execution,
                desc_room_harvest,
                id_room_harvest,
                desc_lab_test_parameter,
                id_lab_test_parameter,
                flg_fill_type_parameter,
                nvl(flg_mov_pat, 'N') flg_mov_pat,
                nvl(flg_first_result, 'DTN') flg_first_result,
                nvl(flg_mov_recipient, 'Y') flg_mov_recipient,
                nvl(flg_harvest, 'Y') flg_harvest,
                nvl(flg_execute, 'Y') flg_execute,
                flg_justify,
                flg_interface,
                flg_duplicate_warn,
                flg_priority
  FROM (SELECT tmp.desc_translation AS desc_lab_test_sample_type,
               tmp.desc_alias,
               b.id_content         id_cnt_lab_test_sample_type,
               NULL                 AS desc_lab_test_cat,
               NULL                 AS id_cnt_lab_test_cat,
               NULL                 AS desc_sample_recipient,
               NULL                 AS id_cnt_sample_recipient,
               NULL                 AS desc_room_execution,
               NULL                 AS id_room_execution,
               NULL                 AS desc_room_harvest,
               NULL                 AS id_room_harvest,
               NULL                 AS desc_lab_test_parameter,
               NULL                 AS id_lab_test_parameter,
               NULL                 AS flg_fill_type_parameter,
               NULL                 AS flg_mov_pat,
               NULL                 AS flg_first_result,
               NULL                 AS flg_mov_recipient,
               NULL                 AS flg_harvest,
               NULL                 AS flg_fill_type,
               NULL                 AS flg_execute,
               NULL                 AS flg_justify,
               NULL                 AS flg_interface,
               NULL                 AS flg_duplicate_warn,
               NULL                 AS flg_priority
          FROM analysis_sample_type b
          JOIN tmp tmp
            ON tmp.id_cnt_lab_test_sample_type = b.id_content)
 ORDER BY 1;

