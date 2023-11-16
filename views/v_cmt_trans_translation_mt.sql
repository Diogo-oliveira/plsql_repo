CREATE OR REPLACE VIEW V_CMT_TRANS_TRANSLATION_MT AS
SELECT code_translation,
       module,
       table_name,
       source_language,
       portuguese_pt,
       portuguese_br,
       portuguese_ao,
       portuguese_mz,
       english_us,
       english_uk,
       english_sa,
       spanish_es,
       spanish_cl,
       spanish_mx,
       french_fr,
       french_ch,
       italian_it,
       chinese_zh_cn,
       chinese_zh_tw,
       czech_cz,
       arabic_ar_sa
  FROM (SELECT t.code_translation,
               t.module,
               t.table_name,
               CASE pk_cmt_content_core.get_source_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'))
                   WHEN 1 THEN
                    t.desc_lang_1
                   WHEN 2 THEN
                    t.desc_lang_2
                   WHEN 3 THEN
                    t.desc_lang_3
                   WHEN 4 THEN
                    t.desc_lang_4
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
               END "SOURCE_LANGUAGE",
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 1),
                      1,
                      t.desc_lang_1,
                      NULL) portuguese_pt,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 2),
                      1,
                      t.desc_lang_2,
                      NULL) english_us,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 3),
                      1,
                      t.desc_lang_3,
                      NULL) spanish_es,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 5),
                      1,
                      t.desc_lang_5,
                      NULL) italian_it,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 6),
                      1,
                      t.desc_lang_6,
                      NULL) french_fr,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 7),
                      1,
                      t.desc_lang_7,
                      NULL) english_uk,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 8),
                      1,
                      t.desc_lang_8,
                      NULL) english_sa,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 11),
                      1,
                      t.desc_lang_11,
                      NULL) portuguese_br,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 12),
                      1,
                      t.desc_lang_12,
                      NULL) chinese_zh_cn,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 13),
                      1,
                      t.desc_lang_13,
                      NULL) chinese_zh_tw,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 16),
                      1,
                      t.desc_lang_16,
                      NULL) spanish_cl,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 17),
                      1,
                      t.desc_lang_17,
                      NULL) spanish_mx,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 18),
                      1,
                      t.desc_lang_18,
                      NULL) french_ch,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 19),
                      1,
                      t.desc_lang_19,
                      NULL) portuguese_ao,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 20),
                      1,
                      t.desc_lang_20,
                      NULL) arabic_ar_sa,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 21),
                      1,
                      t.desc_lang_21,
                      NULL) czech_cz,
               decode(pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 22),
                      1,
                      t.desc_lang_22,
                      NULL) portuguese_mz
          FROM alert_core_data.translation t
          JOIN alert_core_data.trl_versioning tv
            ON t.table_name = tv.table_name
          JOIN alert_core_data.cmt_translation_tbl_users ttu
            ON tv.table_name = ttu.table_name
           AND ttu.flg_available = 'Y'
           AND ttu.username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME')
         WHERE tv.flg_translatable = 'Y'
           AND tv.trl_owner = 'ALERT_CORE_DATA'
           AND tv.trl_tbl_name = 'TRANSLATION')
 WHERE source_language IS NOT NULL
 ORDER BY 4;
