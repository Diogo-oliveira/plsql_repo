CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_TRANSLATION_QUESTION AS
SELECT code_translation, desc_translation
  FROM (SELECT code_translation,
               CASE to_number(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'))
                   WHEN 1 THEN
                    t.desc_lang_1
                   WHEN 2 THEN
                    t.desc_lang_2
                   WHEN 3 THEN
                    t.desc_lang_3
                   WHEN 5 THEN
                    t.desc_lang_5
                   WHEN 6 THEN
                    t.desc_lang_6
                   WHEN 7 THEN
                    t.desc_lang_7
                   WHEN 8 THEN
                    t.desc_lang_8
                   WHEN 11 THEN
                    t.desc_lang_11
                   WHEN 12 THEN
                    t.desc_lang_12
                   WHEN 13 THEN
                    t.desc_lang_13
                   WHEN 16 THEN
                    t.desc_lang_16
                   WHEN 17 THEN
                    t.desc_lang_17
                   WHEN 18 THEN
                    t.desc_lang_18
                   WHEN 19 THEN
                    t.desc_lang_19
                   WHEN 20 THEN
                    t.desc_lang_20
                   WHEN 21 THEN
                    t.desc_lang_21
                   WHEN 22 THEN
                    t.desc_lang_22
               END desc_translation
          FROM translation t
         WHERE t.table_name = 'QUESTIONNAIRE')
 WHERE desc_translation IS NOT NULL;

