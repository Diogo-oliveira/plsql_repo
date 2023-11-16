CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_FREQ AS
WITH tmp_dcs AS
 (SELECT /*+ materialized */
   c.id_dep_clin_serv, a.id_content, a.code_clinical_service, d.id_department, d.code_department
    FROM clinical_service a
    JOIN dep_clin_serv c
      ON c.id_clinical_service = a.id_clinical_service
    JOIN department d
      ON d.id_department = c.id_department
    JOIN software_dept sd
      ON sd.id_dept = d.id_dept
   WHERE a.flg_available = 'Y'
     AND d.flg_available = 'Y'
     AND c.flg_available = 'Y'
     AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
     AND sd.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
temp AS
 (SELECT /*+ MATERIALIZED */
  DISTINCT id_analysis, id_sample_type, id_cnt_lab_test_sample_type, desc_lab_test_sample_type
    FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                        b.code_analysis_sample_type)
                    FROM dual) AS desc_lab_test_sample_type,
                 b.id_analysis,
                 b.id_sample_type,
                 b.id_content AS id_cnt_lab_test_sample_type
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
   WHERE desc_lab_test_sample_type IS NOT NULL)
SELECT desc_lab_test_sample_type,
       id_cnt_lab_test_sample_type,
       desc_service,
       id_service,
       desc_clinical_service,
       id_cnt_clinical_service,
       id_dep_clin_serv
  FROM (SELECT tmp.desc_lab_test_sample_type,
               tmp.id_cnt_lab_test_sample_type,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      tmp_dcs.code_department)
                  FROM dual) AS desc_service,
               tmp_dcs.id_department AS id_service,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      tmp_dcs.code_clinical_service)
                  FROM dual) AS desc_clinical_service,
               tmp_dcs.id_content AS id_cnt_clinical_service,
               tmp_dcs.id_dep_clin_serv
          FROM analysis_dep_clin_serv adcs
          JOIN temp tmp
            ON adcs.id_analysis = tmp.id_analysis
           AND adcs.id_sample_type = tmp.id_sample_type
          JOIN tmp_dcs tmp_dcs
            ON tmp_dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
         WHERE adcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND adcs.flg_available = 'Y'
           AND adcs.id_analysis_group IS NULL)
 WHERE desc_clinical_service IS NOT NULL
   AND desc_service IS NOT NULL
 ORDER BY 3, 5, 1;

