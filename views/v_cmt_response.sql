CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_RESPONSE AS
SELECT "DESC_RESPONSE", "ID_CNT_RESPONSE", "FLG_FREE_TEXT", "GENDER", "AGE_MIN", "AGE_MAX"
  FROM (SELECT t.desc_translation desc_response,
               r.id_content       id_cnt_response,
               r.flg_free_text,
               r.gender,
               r.age_min,
               r.age_max
          FROM alert.response r
          JOIN alert.v_cmt_translation_response t
            ON t.code_translation = r.code_response
         WHERE r.flg_available = 'Y')
 WHERE desc_response IS NOT NULL;

