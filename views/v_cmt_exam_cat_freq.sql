CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_EXAM_CAT_FREQ AS
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
SELECT desc_exam_cat,
       id_cnt_exam_cat,
       "DESC_SERVICE",
       "ID_SERVICE",
       "DESC_CLINICAL_SERVICE",
       "ID_CNT_CLINICAL_SERVICE",
       "ID_DEP_CLIN_SERV"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_exam_cat)
                  FROM dual) AS desc_exam_cat,
               e.id_content id_cnt_exam_cat,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      tmp_dcs.code_department)
                  FROM dual) AS desc_service,
               tmp_dcs.id_department AS id_service,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      tmp_dcs.code_clinical_service)
                  FROM dual) AS desc_clinical_service,
               tmp_dcs.id_content AS id_cnt_clinical_service,
               tmp_dcs.id_dep_clin_serv
          FROM exam_cat_dcs ecdcs
          JOIN tmp_dcs tmp_dcs
            ON tmp_dcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv
          JOIN exam_cat e
            ON e.id_exam_cat = ecdcs.id_exam_cat
         WHERE e.flg_available = 'Y')
 WHERE desc_clinical_service IS NOT NULL
   AND desc_exam_cat IS NOT NULL
 ORDER BY 3, 5, 1;

