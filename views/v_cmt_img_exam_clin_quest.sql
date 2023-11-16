CREATE OR REPLACE VIEW v_cmt_img_exam_clin_quest AS
WITH temp AS
 (SELECT /*+ materialized */
  DISTINCT avlb.id_img_exam AS id_exam, avlb.desc_img_exam, avlb.id_cnt_img_exam
    FROM v_cmt_img_exam_available avlb)
SELECT desc_img_exam,
       id_cnt_img_exam,
       desc_clinical_question,
       desc_response,
       id_cnt_question_response,
       flg_type,
       flg_mandatory,
       rank,
       flg_time,
       flg_copy,
       flg_validation,
       flg_exterior,
       id_unit_measure
  FROM (SELECT tmp.desc_img_exam,
               tmp.id_cnt_img_exam,
               ttt.desc_translation  desc_clinical_question,
               tttt.desc_translation desc_response,
               e.id_content          id_cnt_question_response,
               a.flg_type,
               a.flg_mandatory,
               a.rank,
               a.flg_time,
               a.flg_copy,
               a.flg_validation,
               a.flg_exterior,
               a.id_unit_measure
          FROM exam_questionnaire a
          JOIN temp tmp
            ON tmp.id_exam = a.id_exam
          JOIN questionnaire_response e
            ON e.id_questionnaire = a.id_questionnaire
           AND e.id_response = a.id_response
           AND e.flg_available = 'Y'
          JOIN questionnaire b
            ON b.id_questionnaire = a.id_questionnaire
           AND b.flg_available = 'Y'
          JOIN exam c
            ON c.id_exam = a.id_exam
          JOIN exam_cat ec
            ON ec.id_exam_cat = c.id_exam_cat
           AND ec.flg_available = 'Y'
          JOIN response d
            ON d.id_response = a.id_response
           AND d.flg_available = 'Y'
          JOIN v_cmt_translation_question ttt
            ON ttt.code_translation = b.code_questionnaire
          JOIN v_cmt_translation_response tttt
            ON tttt.code_translation = d.code_response
         WHERE a.flg_available = 'Y'
           AND a.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
 WHERE desc_img_exam IS NOT NULL
   AND desc_clinical_question IS NOT NULL
 ORDER BY 1, 3;
