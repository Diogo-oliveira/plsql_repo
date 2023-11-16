CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DEP_CLIN_SERV AS
SELECT "DESC_DEPARTMENT",
       "ID_DEPARTMENT",
       "DESC_SERVICE",
       "ID_SERVICE",
       "DESC_CLINICAL_SERVICE",
       "ID_CNT_CLINICAL_SERVICE",
       "ID_CLINICAL_SERVICE",
       "ID_DEP_CLIN_SERV"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), dt.code_dept)
                  FROM dual) AS desc_department,
               dt.id_dept AS id_department,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), d.code_department)
                  FROM dual) desc_service,
               d.id_department AS id_service,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      a.code_clinical_service)
                  FROM dual) desc_clinical_service,
               a.id_content id_cnt_clinical_service,
               a.id_clinical_service,
               c.id_dep_clin_serv
          FROM clinical_service a
          JOIN dep_clin_serv c
            ON c.id_clinical_service = a.id_clinical_service
          JOIN department d
            ON d.id_department = c.id_department
          JOIN software_dept sd
            ON sd.id_dept = d.id_dept
          JOIN dept dt
            ON dt.id_dept = d.id_dept
         WHERE d.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND sd.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND d.flg_available = 'Y'
           AND a.flg_available = 'Y'
           AND c.flg_available = 'Y'
           AND dt.flg_available = 'Y')
 WHERE desc_department IS NOT NULL
   AND desc_service IS NOT NULL
   AND desc_clinical_service IS NOT NULL
 ORDER BY 1, 3, 5;

