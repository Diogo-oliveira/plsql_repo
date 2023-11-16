CREATE OR REPLACE VIEW V_CMT_LAB_TEST_ST_AVAILABLE AS
SELECT "DESC_LAB_TEST_SAMPLE_TYPE",
       "DESC_ALIAS",
       "ID_CNT_LAB_TEST_SAMPLE_TYPE",
       "DESC_LAB_TEST_CAT",
       "ID_CNT_LAB_TEST_CAT",
       "DESC_SAMPLE_RECIPIENT",
       "ID_CNT_SAMPLE_RECIPIENT",
       "DESC_ROOM_EXECUTION",
       "ID_ROOM_EXECUTION",
       "DESC_ROOM_HARVEST",
       "ID_ROOM_HARVEST",
       "HARVEST_INSTRUCTIONS",
       "DESC_LAB_TEST_PARAMETER",
       "ID_LAB_TEST_PARAMETER",
       "FLG_FILL_TYPE_PARAMETER",
       "FLG_MOV_PAT",
       "FLG_FIRST_RESULT",
       "FLG_MOV_RECIPIENT",
       "FLG_HARVEST",
       "FLG_EXECUTE",
       "FLG_JUSTIFY",
       "FLG_INTERFACE",
       "FLG_DUPLICATE_WARN",
       "FLG_PRIORITY"
  FROM (SELECT DISTINCT desc_lab_test_sample_type,
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
                        harvest_instructions,
                        desc_lab_test_parameter,
                        id_lab_test_parameter,
                        flg_fill_type_parameter,
                        flg_mov_pat,
                        flg_first_result,
                        flg_mov_recipient,
                        flg_harvest,
                        flg_execute,
                        flg_justify,
                        flg_interface,
                        flg_duplicate_warn,
                        flg_priority
          FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              b.code_analysis_sample_type)
                          FROM dual) AS desc_lab_test_sample_type,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              asta.code_ast_alias)
                          FROM dual) AS desc_alias,
                       b.id_content id_cnt_lab_test_sample_type,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_exam_cat)
                          FROM dual) AS desc_lab_test_cat,
                       e.id_content id_cnt_lab_test_cat,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              sr.code_sample_recipient)
                          FROM dual) AS desc_sample_recipient,
                       sr.id_content id_cnt_sample_recipient,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), rt.code_room)
                          FROM dual) AS desc_room_execution,
                       art.id_room id_room_execution,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), rm.code_room)
                          FROM dual) AS desc_room_harvest,
                       arm.id_room id_room_harvest,
                       d.harvest_instructions,
                       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                              app.code_analysis_parameter)
                          FROM dual) AS desc_lab_test_parameter,
                       app.id_analysis_parameter AS id_lab_test_parameter,
                       ap.flg_fill_type AS flg_fill_type_parameter,
                       d.flg_mov_pat,
                       d.flg_first_result,
                       d.flg_mov_recipient,
                       d.flg_harvest,
                       d.flg_execute,
                       d.flg_justify,
                       d.flg_interface,
                       d.flg_duplicate_warn,
                       d.flg_priority,
                       row_number() over(PARTITION BY b.id_content ORDER BY art.id_analysis_instit_soft NULLS LAST, asta.id_software DESC, arm.id_analysis_instit_soft NULLS LAST, ap.id_analysis_parameter DESC) AS rn
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
                   AND art.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND art.flg_default = 'Y'
                   AND art.flg_type = 'T'
                   AND (art.id_analysis_instit_soft IS NULL OR art.id_analysis_instit_soft = d.id_analysis_instit_soft)
                  JOIN analysis_room arm
                    ON b.id_analysis = arm.id_analysis
                   AND b.id_sample_type = arm.id_sample_type
                   AND arm.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND (arm.flg_default = 'Y' OR d.flg_harvest = 'Y')
                   AND arm.flg_type = 'M'
                   AND (arm.id_analysis_instit_soft IS NULL OR arm.id_analysis_instit_soft = d.id_analysis_instit_soft)
                  JOIN room rt
                    ON art.id_room = rt.id_room
                   AND rt.flg_available = 'Y'
                  JOIN room rm
                    ON arm.id_room = rm.id_room
                   AND rm.flg_available = 'Y'
                  JOIN department ddt
                    ON ddt.id_department = rt.id_department
                   AND ddt.flg_available = 'Y'
                   AND ddt.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                  JOIN department ddm
                    ON ddm.id_department = rm.id_department
                   AND ddm.flg_available = 'Y'
                   AND ddm.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                  JOIN analysis_param ap
                    ON ap.id_analysis = d.id_analysis
                   AND ap.id_sample_type = d.id_sample_type
                   AND ap.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND ap.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ap.flg_available = 'Y'
                  JOIN analysis_parameter app
                    ON app.id_analysis_parameter = ap.id_analysis_parameter
                   AND app.flg_available = 'Y'
                  LEFT JOIN analysis_sample_type_alias asta
                    ON asta.id_analysis = b.id_analysis
                   AND asta.id_sample_type = b.id_sample_type
                   AND asta.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0)
                   AND asta.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE b.flg_available = 'Y')
         WHERE rn = 1
           AND desc_lab_test_sample_type IS NOT NULL)
 ORDER BY 1;
