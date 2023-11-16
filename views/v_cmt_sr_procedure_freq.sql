CREATE OR REPLACE VIEW V_CMT_SR_PROCEDURE_FREQ AS
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
  DISTINCT id_cnt_sr_procedure, desc_sr_procedure, id_sr_procedure as id_intervention
    FROM v_cmt_sr_procedure_available)
SELECT desc_sr_procedure,
       id_cnt_sr_procedure,
       "DESC_SERVICE",
       "ID_SERVICE",
       "DESC_CLINICAL_SERVICE",
       "ID_CNT_CLINICAL_SERVICE",
       "ID_DEP_CLIN_SERV"
  FROM (SELECT tmp.desc_sr_procedure,
               tmp.id_cnt_sr_procedure,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      tmp_dcs.code_department)
                  FROM dual) AS desc_service,
               tmp_dcs.id_department AS id_service,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      tmp_dcs.code_clinical_service)
                  FROM dual) AS desc_clinical_service,
               tmp_dcs.id_content AS id_cnt_clinical_service,
               tmp_dcs.id_dep_clin_serv
          FROM interv_dep_clin_serv idcs
          JOIN tmp_dcs tmp_dcs
            ON tmp_dcs.id_dep_clin_serv = idcs.id_dep_clin_serv
          JOIN temp tmp
            ON idcs.id_intervention = tmp.id_intervention
         WHERE idcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND idcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND sys_context('ALERT_CONTEXT', 'ID_SOFTWARE') = 2
           AND idcs.flg_type = 'M')
 WHERE desc_clinical_service IS NOT NULL
   AND desc_service IS NOT NULL
 ORDER BY 3, 5, 1;
