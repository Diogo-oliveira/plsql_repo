CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_CLINICAL_QUESTION_S AS
SELECT "DESC_CLINICAL_QUESTION","ID_CNT_CLINICAL_QUESTION","GENDER","AGE_MIN","AGE_MAX"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), q.code_questionnaire)
                  FROM dual) desc_clinical_question,
               q.id_content id_cnt_clinical_question,
               q.gender,
               q.age_min,
               q.age_max
          FROM alert.questionnaire q
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'QUESTIONNAIRE.CODE_QUESTIONNAIRE')) t
            ON t.code_translation = q.code_questionnaire
         WHERE q.flg_available = 'Y')
 WHERE desc_clinical_question IS NOT NULL;

