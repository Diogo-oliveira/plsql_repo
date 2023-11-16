CREATE OR REPLACE VIEW V_CMT_PROCEDURE_FREQ AS
WITH tmp_dcs AS
 (SELECT /*+ materialized */
  DISTINCT c.id_dep_clin_serv,
           a.id_content,
           (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_clinical_service)
              FROM dual) AS desc_clinical_service,
           d.id_department,
           (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), d.code_department)
              FROM dual) AS desc_service
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
  DISTINCT id_cnt_procedure, desc_procedure, id_procedure AS id_intervention
    FROM v_cmt_procedure_available)
SELECT "DESC_PROCEDURE",
       "ID_CNT_PROCEDURE",
       "DESC_SERVICE",
       "ID_SERVICE",
       "DESC_CLINICAL_SERVICE",
       "ID_CNT_CLINICAL_SERVICE",
       "ID_DEP_CLIN_SERV"
  FROM (SELECT tmp.desc_procedure,
               tmp.id_cnt_procedure,
               tmp_dcs.desc_service,
               tmp_dcs.id_department         AS id_service,
               tmp_dcs.desc_clinical_service,
               tmp_dcs.id_content            AS id_cnt_clinical_service,
               tmp_dcs.id_dep_clin_serv
          FROM interv_dep_clin_serv idcs
          JOIN temp tmp
            ON idcs.id_intervention = tmp.id_intervention
          JOIN tmp_dcs tmp_dcs
            ON tmp_dcs.id_dep_clin_serv = idcs.id_dep_clin_serv
         WHERE idcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND idcs.flg_type = 'M') res_data
 WHERE res_data.desc_clinical_service IS NOT NULL
   AND res_data.desc_service IS NOT NULL
 ORDER BY 3, 5, 1;
