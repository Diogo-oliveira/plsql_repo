CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_QUESTION_RESPONSE_S AS
SELECT "DESC_CLINICAL_QUESTION","ID_CNT_CLINICAL_QUESTION","DESC_RESP","ID_CNT_RESPONSE","ID_CNT_QUESTION_RESPONSE","RANK","GENDER","AGE_MIN","AGE_MAX","DESC_QUEST_PARENT","DESC_RESP_PARENT","ID_CNT_QUESTION_RESPONSE_PRT"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), q.code_questionnaire)
                  FROM dual) desc_clinical_question,
               q.id_content id_cnt_clinical_question,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), r.code_response)
                  FROM dual) desc_resp,
               r.id_content id_cnt_response,
               qr.id_content id_cnt_question_response,
               qr.rank,
               q.gender,
               q.age_min,
               q.age_max,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), qp.code_questionnaire)
                  FROM dual) desc_quest_parent,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), rp.code_response)
                  FROM dual) desc_resp_parent,
               qr_prt.id_content id_cnt_question_response_prt
          FROM alert.questionnaire_response qr
         INNER JOIN alert.questionnaire q
            ON q.id_questionnaire = qr.id_questionnaire
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'QUESTIONNAIRE.CODE_QUESTIONNAIRE')) t
            ON t.code_translation = q.code_questionnaire
          LEFT OUTER JOIN alert.response r
            ON qr.id_response = r.id_response
           AND r.flg_available = 'Y'
          LEFT OUTER JOIN alert.questionnaire qp
            ON qp.id_questionnaire = qr.id_questionnaire_parent
           AND qp.flg_available = 'Y'
           AND pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), qp.code_questionnaire) IS NOT NULL
          LEFT OUTER JOIN alert.response rp
            ON rp.id_response = qr.id_response_parent
           AND rp.flg_available = 'Y'
           AND pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), rp.code_response) IS NOT NULL
          LEFT OUTER JOIN alert.questionnaire_response qr_prt
            ON qr.id_questionnaire_parent = qr_prt.id_questionnaire
           AND qr_prt.id_response = qr.id_response_parent
         WHERE qr.flg_available = 'Y'
           AND q.flg_available = 'Y')
 WHERE desc_clinical_question IS NOT NULL
   AND desc_resp IS NOT NULL;

