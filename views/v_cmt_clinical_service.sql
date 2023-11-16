CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_CLINICAL_SERVICE AS
SELECT desc_clinical_service,
       id_cnt_clinical_service,
       abbreviation,
       desc_clin_serv_parent,
       id_cnt_clin_serv_parent,
       id_clinical_service
  FROM (SELECT t.desc_translation desc_clinical_service,
               a.id_clinical_service,
               a.id_content id_cnt_clinical_service,
               a.abbreviation,
               tt.desc_translation desc_clin_serv_parent,
               (SELECT id_content
                  FROM alert.clinical_service
                 WHERE id_clinical_service = a.id_clinical_service_parent) id_cnt_clin_serv_parent
          FROM alert.clinical_service a
          LEFT JOIN alert.clinical_service b
            ON b.id_clinical_service = a.id_clinical_service_parent
          JOIN alert.v_cmt_translation_clin_serv t
            ON t.code_translation = a.code_clinical_service
          LEFT JOIN alert.v_cmt_translation_clin_serv tt
            ON tt.code_translation = b.code_clinical_service
         WHERE a.flg_available = 'Y')
 WHERE desc_clinical_service IS NOT NULL
 ORDER BY desc_clinical_service;

