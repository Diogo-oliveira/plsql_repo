CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_CLINICAL_QUESTION AS
SELECT "DESC_CLINICAL_QUESTION", "ID_CNT_CLINICAL_QUESTION", "GENDER", "AGE_MIN", "AGE_MAX", "ID_CLINICAL_QUESTION"
  FROM (SELECT t.desc_translation desc_clinical_question,
               q.id_content       id_cnt_clinical_question,
               q.gender,
               q.age_min,
               q.age_max,
               id_questionnaire   AS id_clinical_question
          FROM alert.questionnaire q
          JOIN alert.v_cmt_translation_question t
            ON t.code_translation = q.code_questionnaire
         WHERE q.flg_available = 'Y')
 WHERE desc_clinical_question IS NOT NULL;

