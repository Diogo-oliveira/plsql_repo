CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_LAB_TEST_GROUP_FREQ AS
WITH tmp_dcs AS
 (SELECT /*+ materialized */
   c.id_dep_clin_serv, a.id_content, a.code_clinical_service, d.id_department, d.code_department
    FROM alert.clinical_service a
    JOIN alert.dep_clin_serv c
      ON c.id_clinical_service = a.id_clinical_service
    JOIN alert.department d
      ON d.id_department = c.id_department
    JOIN alert.software_dept sd
      ON sd.id_dept = d.id_dept
   WHERE a.flg_available = 'Y'
     AND d.flg_available = 'Y'
     AND c.flg_available = 'Y'
     AND d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
     AND sd.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
SELECT "DESC_LAB_TEST_GROUP",
       "ID_CNT_LAB_TEST_GROUP",
       "DESC_SERVICE",
       "ID_SERVICE",
       "DESC_CLINICAL_SERVICE",
       "ID_CNT_CLINICAL_SERVICE",
       "ID_DEP_CLIN_SERV"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), ag.code_analysis_group)
                  FROM dual) AS desc_lab_test_group,
               ag.id_content AS id_cnt_lab_test_group,
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
          JOIN analysis_group ag
            ON ag.id_analysis_group = adcs.id_analysis_group
           AND ag.flg_available = 'Y'
          JOIN tmp_dcs tmp_dcs
            ON tmp_dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
         WHERE adcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND adcs.flg_available = 'Y'
           AND adcs.id_analysis IS NULL
           AND adcs.id_sample_type IS NULL)
 WHERE desc_lab_test_group IS NOT NULL
   AND desc_clinical_service IS NOT NULL
 ORDER BY 3, 5, 1;

