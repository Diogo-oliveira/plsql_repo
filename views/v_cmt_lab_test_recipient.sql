CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_RECIPIENT AS
WITH temp AS
 (SELECT /*+ MATERIALIZED */
  DISTINCT b.id_analysis, b.id_sample_type, d.id_analysis_instit_soft
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
     AND (art.id_analysis_instit_soft IS NULL OR art.id_analysis_instit_soft = d.id_analysis_instit_soft)
    JOIN analysis_room arm
      ON b.id_analysis = arm.id_analysis
     AND b.id_sample_type = arm.id_sample_type
     AND d.id_institution = arm.id_institution
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
     AND ddt.id_institution = d.id_institution
    JOIN department ddm
      ON ddm.id_department = rm.id_department
     AND ddm.flg_available = 'Y'
     AND ddm.id_institution = d.id_institution
    JOIN analysis_param ap
      ON ap.id_analysis = d.id_analysis
     AND ap.id_sample_type = d.id_sample_type
     AND d.id_institution = ap.id_institution
     AND d.id_software = ap.id_software
     AND ap.flg_available = 'Y'
    JOIN analysis_parameter app
      ON app.id_analysis_parameter = ap.id_analysis_parameter
     AND app.flg_available = 'Y'
   WHERE b.flg_available = 'Y')
SELECT "DESC_LAB_TEST_SAMPLE_TYPE",
       "ID_CNT_LAB_TEST_SAMPLE_TYPE",
       "DESC_SAMPLE_RECIPIENT",
       "ID_CNT_SAMPLE_RECIPIENT",
       "FLG_DEFAULT",
       "ID_ANALYSIS_INSTIT_RECIPIENT"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      b.code_analysis_sample_type)
                  FROM dual) desc_lab_test_sample_type,
               b.id_content id_cnt_lab_test_sample_type,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      sr.code_sample_recipient)
                  FROM dual) desc_sample_recipient,
               sr.id_content id_cnt_sample_recipient,
               e.flg_default,
               e.id_analysis_instit_recipient
          FROM analysis_sample_type b
          JOIN temp tmp
            ON b.id_analysis = tmp.id_analysis
           AND b.id_sample_type = tmp.id_sample_type
          JOIN analysis_instit_recipient e
            ON e.id_analysis_instit_soft = tmp.id_analysis_instit_soft
          JOIN sample_recipient sr
            ON sr.id_sample_recipient = e.id_sample_recipient
           AND sr.flg_available = 'Y')
 WHERE desc_lab_test_sample_type IS NOT NULL
   AND desc_sample_recipient IS NOT NULL;

