CREATE OR REPLACE VIEW v_cmt_other_exam_complaint AS
WITH temp AS
 (SELECT /*+ materialized */
  DISTINCT id_cnt_other_exam, id_other_exam id_exam, desc_other_exam
    FROM v_cmt_other_exam_available),
temp3 AS
 (SELECT decode((SELECT pk_sysconfig.get_config(i_code_cf => 'COMPLAINT_FILTER',
                                               i_prof    => profissional(0,
                                                                         sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                         sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) AS RESULT
                  FROM dual),
                'DEP_CLIN_SERV',
                'CT',
                'C') AS RESULT
    FROM dual),
temp2 AS
 (SELECT /*+ materialized */
  DISTINCT id_complaint, desc_complaint, id_content
    FROM (SELECT c.id_complaint,
                 c.id_content,
                 (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), c.code_complaint)
                    FROM dual) desc_complaint
            FROM doc_template_context b
            JOIN temp3 temp3
              ON b.flg_type = temp3.result
            JOIN complaint c
              ON b.id_context = c.id_complaint
             AND c.flg_available = 'Y'
           WHERE b.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
             AND b.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
   WHERE desc_complaint IS NOT NULL)
SELECT desc_other_exam, id_cnt_other_exam, desc_complaint, id_cnt_complaint
  FROM (SELECT DISTINCT tmp.desc_other_exam,
                        tmp.id_cnt_other_exam,
                        tmp2.desc_complaint,
                        tmp2.id_content id_cnt_complaint
          FROM exam_complaint ec
          JOIN temp tmp
            ON tmp.id_exam = ec.id_exam
          JOIN temp2 tmp2
            ON tmp2.id_complaint = ec.id_complaint
         WHERE ec.flg_available = 'Y')
 ORDER BY 3, 1 ASC;
