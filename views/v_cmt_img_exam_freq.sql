CREATE OR REPLACE VIEW v_cmt_img_exam_freq AS
WITH tmp_dcs AS
 (SELECT /*+ materialized */
  DISTINCT c.id_dep_clin_serv,
           a.id_content,
           (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_clinical_service)
              FROM dual) desc_clinical_service,
           d.id_department,
           (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), d.code_department)
              FROM dual) desc_service
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
 (SELECT /*+ materialized */
  DISTINCT id_cnt_img_exam, id_img_exam id_exam, desc_img_exam
    FROM v_cmt_img_exam_available)
SELECT desc_img_exam,
       id_cnt_img_exam,
       desc_service,
       id_service,
       desc_clinical_service,
       id_cnt_clinical_service,
       id_dep_clin_serv
  FROM (SELECT tmp.desc_img_exam,
               tmp.id_cnt_img_exam,
               tmp_dcs.desc_service,
               tmp_dcs.id_department         id_service,
               tmp_dcs.desc_clinical_service,
               tmp_dcs.id_content            id_cnt_clinical_service,
               tmp_dcs.id_dep_clin_serv
          FROM exam_dep_clin_serv edcs
          JOIN temp tmp
            ON tmp.id_exam = edcs.id_exam
          JOIN tmp_dcs tmp_dcs
            ON tmp_dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
         WHERE edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND edcs.flg_type = 'M') res_data
 WHERE res_data.desc_clinical_service IS NOT NULL
 ORDER BY 3, 5, 1;
