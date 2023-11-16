CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROCEDURE_CLIN_QUEST AS
WITH temp AS
 (SELECT /*+ MATERIALIZED */
  DISTINCT avlb.id_procedure AS id_intervention, avlb.id_cnt_procedure, avlb.desc_procedure
    FROM v_cmt_procedure_available avlb)
SELECT desc_procedure,
       id_cnt_procedure,
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
  FROM (SELECT tmp.desc_procedure,
               tmp.id_cnt_procedure,
               ttt.desc_translation desc_clinical_question,
               tttt.desc_translation desc_response,
               e.id_content id_cnt_question_response,
               a.flg_type,
               decode(a.flg_mandatory, 'Y', 'Yes', 'N', 'No', NULL) flg_mandatory,
               a.rank,
               a.flg_time,
               decode(a.flg_copy, 'Y', 'Yes', 'N', 'No', NULL) flg_copy,
               decode(a.flg_validation, 'Y', 'Yes', 'N', 'No', NULL) flg_validation,
               decode(a.flg_exterior, 'Y', 'Yes', 'N', 'No', NULL) flg_exterior,
               a.id_unit_measure
          FROM interv_questionnaire a
          JOIN temp tmp
            ON tmp.id_intervention = a.id_intervention
          JOIN questionnaire_response e
            ON e.id_questionnaire = a.id_questionnaire
           AND e.id_response = a.id_response
           AND e.flg_available = 'Y'
          JOIN questionnaire b
            ON b.id_questionnaire = a.id_questionnaire
           AND b.flg_available = 'Y'
          JOIN intervention c
            ON c.id_intervention = a.id_intervention
          JOIN response d
            ON d.id_response = a.id_response
           AND d.flg_available = 'Y'
          JOIN v_cmt_translation_question ttt
            ON ttt.code_translation = b.code_questionnaire
          JOIN v_cmt_translation_response tttt
            ON tttt.code_translation = d.code_response
         WHERE a.flg_available = 'Y'
           AND a.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
 WHERE desc_procedure IS NOT NULL
   AND desc_clinical_question IS NOT NULL;

