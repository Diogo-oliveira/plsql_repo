CREATE OR REPLACE VIEW V_CMT_TRANS_TRANSLATION AS
SELECT t.code_translation,
       t.module,
       t.table_name,
       t.desc_lang_1      portuguese_pt,
       t.desc_lang_11     portuguese_br,
       t.desc_lang_19     portuguese_ao,
       t.desc_lang_22     portuguese_mz,
       t.desc_lang_2      english_us,
       t.desc_lang_7      english_uk,
       t.desc_lang_8      english_sa,
       t.desc_lang_3      spanish_es,
       t.desc_lang_16     spanish_cl,
       t.desc_lang_17     spanish_mx,
       t.desc_lang_6      french_fr,
       t.desc_lang_18     french_ch,
       t.desc_lang_5      italian_it,
       t.desc_lang_12     chinese_zh_cn,
       t.desc_lang_13     chinese_zh_tw,
       t.desc_lang_21     czech_cz,
       t.desc_lang_20     arabic_ar_sa
  FROM alert_core_data.translation t
  JOIN alert_core_data.trl_versioning tv
    ON t.table_name = tv.table_name
 WHERE tv.flg_translatable = 'Y'
   AND tv.trl_owner = 'ALERT_CORE_DATA'
   AND tv.trl_tbl_name = 'TRANSLATION';
