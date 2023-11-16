CREATE OR REPLACE VIEW V_CMT_TRANS_CODES_MT AS
SELECT tmp.*
  FROM (SELECT "TABLE_TRANSLATION",
               "CODE_TRANSLATION",
               "VAL",
               "SOURCE_LANGUAGE",
               "PORTUGUESE_PT",
               "ENGLISH_US",
               "SPANISH_ES",
               "ITALIAN_IT",
               "FRENCH_FR",
               "ENGLISH_UK",
               "ENGLISH_SA",
               "PORTUGUESE_BR",
               "CHINESE_ZH_CN",
               "CHINESE_ZH_TW",
               "SPANISH_CL",
               "SPANISH_MX",
               "FRENCH_CH",
               "PORTUGUESE_AO",
               "ARABIC_AR_SA",
               "CZECH_CZ",
               "PORTUGUESE_MZ"
          FROM (SELECT 'TRANSLATION' table_translation,
                       t.code_translation,
                       NULL AS val,
                       CASE alert.pk_cmt_content_core.get_source_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'))
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
                       END "SOURCE_LANGUAGE",
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            1),
                              1,
                              t.desc_lang_1,
                              NULL) portuguese_pt,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            2),
                              1,
                              t.desc_lang_2,
                              NULL) english_us,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            3),
                              1,
                              t.desc_lang_3,
                              NULL) spanish_es,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            5),
                              1,
                              t.desc_lang_5,
                              NULL) italian_it,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            6),
                              1,
                              t.desc_lang_6,
                              NULL) french_fr,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            7),
                              1,
                              t.desc_lang_7,
                              NULL) english_uk,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            8),
                              1,
                              t.desc_lang_8,
                              NULL) english_sa,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            11),
                              1,
                              t.desc_lang_11,
                              NULL) portuguese_br,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            12),
                              1,
                              t.desc_lang_12,
                              NULL) chinese_zh_cn,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            13),
                              1,
                              t.desc_lang_13,
                              NULL) chinese_zh_tw,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            16),
                              1,
                              t.desc_lang_16,
                              NULL) spanish_cl,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            17),
                              1,
                              t.desc_lang_17,
                              NULL) spanish_mx,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            18),
                              1,
                              t.desc_lang_18,
                              NULL) french_ch,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            19),
                              1,
                              t.desc_lang_19,
                              NULL) portuguese_ao,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            20),
                              1,
                              t.desc_lang_20,
                              NULL) arabic_ar_sa,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            21),
                              1,
                              t.desc_lang_21,
                              NULL) czech_cz,
                       decode(alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                            22),
                              1,
                              t.desc_lang_22,
                              NULL) portuguese_mz
                  FROM alert_core_data.translation t
                  JOIN alert_core_data.trl_versioning tv
                    ON t.table_name = tv.table_name
                   AND tv.trl_owner = 'ALERT_CORE_DATA'
                   AND tv.trl_tbl_name = 'TRANSLATION'
                   AND tv.flg_translatable = 'Y'
                  JOIN alert_core_data.cmt_translation_tbl_users ttu
                    ON t.code_translation = ttu.table_name
                   AND ttu.trl_owner = 'ALERT_CODES'
                   AND ttu.trl_tbl_name = 'ALERT_CODES'
                   AND ttu.flg_available = 'Y'
                   AND ttu.username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME')
                UNION
                SELECT DISTINCT 'SYS_MESSAGE' table_translation,
                                sd0.code_message AS code_translation,
                                NULL AS val,
                                sd0.desc_message source_language,
                                sd1.desc_message portuguese_pt,
                                sd2.desc_message english_us,
                                sd3.desc_message spanish_es,
                                sd5.desc_message italian_it,
                                sd6.desc_message french_fr,
                                sd7.desc_message english_uk,
                                sd8.desc_message english_sa,
                                sd11.desc_message portuguese_br,
                                sd12.desc_message chinese_zh_cn,
                                sd13.desc_message chinese_zh_tw,
                                sd16.desc_message spanish_cl,
                                sd17.desc_message spanish_mx,
                                sd18.desc_message french_ch,
                                sd19.desc_message portuguese_ao,
                                sd20.desc_message arabic_ar_sa,
                                sd21.desc_message czech_cz,
                                sd22.desc_message portuguese_mz
                  FROM sys_message sd0
                  JOIN alert_core_data.cmt_translation_tbl_users ttu
                    ON sd0.code_message = ttu.table_name
                   AND ttu.trl_owner = 'ALERT_CODES'
                   AND ttu.trl_tbl_name = 'ALERT_CODES'
                   AND ttu.flg_available = 'Y'
                   AND ttu.username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME')
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 1
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 1) = 1) sd1
                    ON sd0.code_message = sd1.code_message
                   AND sd0.id_software = sd1.id_software
                   AND sd0.id_institution = sd1.id_institution
                   AND sd0.id_market = sd1.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 2
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 2) = 1) sd2
                    ON sd0.code_message = sd2.code_message
                   AND sd0.id_software = sd2.id_software
                   AND sd0.id_institution = sd2.id_institution
                   AND sd0.id_market = sd2.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 3
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 3) = 1) sd3
                    ON sd0.code_message = sd3.code_message
                   AND sd0.id_software = sd3.id_software
                   AND sd0.id_institution = sd3.id_institution
                   AND sd0.id_market = sd3.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 5
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 5) = 1) sd5
                    ON sd0.code_message = sd5.code_message
                   AND sd0.id_software = sd5.id_software
                   AND sd0.id_institution = sd5.id_institution
                   AND sd0.id_market = sd5.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 6
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 6) = 1) sd6
                    ON sd0.code_message = sd6.code_message
                   AND sd0.id_software = sd6.id_software
                   AND sd0.id_institution = sd6.id_institution
                   AND sd0.id_market = sd6.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 7
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 7) = 1) sd7
                    ON sd0.code_message = sd7.code_message
                   AND sd0.id_software = sd7.id_software
                   AND sd0.id_institution = sd7.id_institution
                   AND sd0.id_market = sd7.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 8
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 8) = 1) sd8
                    ON sd0.code_message = sd8.code_message
                   AND sd0.id_software = sd8.id_software
                   AND sd0.id_institution = sd8.id_institution
                   AND sd0.id_market = sd8.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 9
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 9) = 1) sd9
                    ON sd0.code_message = sd9.code_message
                   AND sd0.id_software = sd9.id_software
                   AND sd0.id_institution = sd9.id_institution
                   AND sd0.id_market = sd9.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 11
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 11) = 1) sd11
                    ON sd0.code_message = sd11.code_message
                   AND sd0.id_software = sd11.id_software
                   AND sd0.id_institution = sd11.id_institution
                   AND sd0.id_market = sd11.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 12
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 12) = 1) sd12
                    ON sd0.code_message = sd12.code_message
                   AND sd0.id_software = sd12.id_software
                   AND sd0.id_institution = sd12.id_institution
                   AND sd0.id_market = sd12.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 13
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 13) = 1) sd13
                    ON sd0.code_message = sd13.code_message
                   AND sd0.id_software = sd13.id_software
                   AND sd0.id_institution = sd13.id_institution
                   AND sd0.id_market = sd13.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 16
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 16) = 1) sd16
                    ON sd0.code_message = sd16.code_message
                   AND sd0.id_software = sd16.id_software
                   AND sd0.id_institution = sd16.id_institution
                   AND sd0.id_market = sd16.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 17
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 17) = 1) sd17
                    ON sd0.code_message = sd17.code_message
                   AND sd0.id_software = sd17.id_software
                   AND sd0.id_institution = sd17.id_institution
                   AND sd0.id_market = sd17.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 18
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 18) = 1) sd18
                    ON sd0.code_message = sd18.code_message
                   AND sd0.id_software = sd18.id_software
                   AND sd0.id_institution = sd18.id_institution
                   AND sd0.id_market = sd18.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 19
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 19) = 1) sd19
                    ON sd0.code_message = sd19.code_message
                   AND sd0.id_software = sd19.id_software
                   AND sd0.id_institution = sd19.id_institution
                   AND sd0.id_market = sd19.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 20
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 20) = 1) sd20
                    ON sd0.code_message = sd20.code_message
                   AND sd0.id_software = sd20.id_software
                   AND sd0.id_institution = sd20.id_institution
                   AND sd0.id_market = sd20.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 21
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 21) = 1) sd21
                    ON sd0.code_message = sd21.code_message
                   AND sd0.id_software = sd21.id_software
                   AND sd0.id_institution = sd21.id_institution
                   AND sd0.id_market = sd21.id_market
                  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                              FROM sys_message
                             WHERE id_language = 22
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 22) = 1) sd22
                    ON sd0.code_message = sd22.code_message
                   AND sd0.id_software = sd22.id_software
                   AND sd0.id_institution = sd22.id_institution
                   AND sd0.id_market = sd22.id_market
                 WHERE sd0.id_institution = 0
                   AND sd0.id_market = 0
                   AND sd0.flg_available = 'Y'
                   AND sd0.id_language =
                       alert.pk_cmt_content_core.get_source_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'))
                UNION
                SELECT DISTINCT 'SYS_DOMAIN' table_translation,
                                sd0.code_domain AS code_translation,
                                sd0.val,
                                sd0.desc_val source_language,
                                sd1.desc_val portuguese_pt,
                                sd2.desc_val english_us,
                                sd3.desc_val spanish_es,
                                sd5.desc_val italian_it,
                                sd6.desc_val french_fr,
                                sd7.desc_val english_uk,
                                sd8.desc_val english_sa,
                                sd11.desc_val portuguese_br,
                                sd12.desc_val chinese_zh_cn,
                                sd13.desc_val chinese_zh_tw,
                                sd16.desc_val spanish_cl,
                                sd17.desc_val spanish_mx,
                                sd18.desc_val french_ch,
                                sd19.desc_val portuguese_ao,
                                sd20.desc_val arabic_ar_sa,
                                sd21.desc_val czech_cz,
                                sd22.desc_val portuguese_mz
                  FROM (SELECT desc_val, code_domain, val
                          FROM sys_domain a
                          JOIN alert_core_data.cmt_translation_tbl_users ttu
                            ON a.code_domain = ttu.table_name
                           AND ttu.trl_owner = 'ALERT_CODES'
                           AND ttu.trl_tbl_name = 'ALERT_CODES'
                           AND ttu.flg_available = 'Y'
                           AND ttu.username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME')
                         WHERE a.id_language =
                               alert.pk_cmt_content_core.get_source_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'))
                           AND a.flg_available = 'Y') sd0
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 1
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 1) = 1) sd1
                    ON sd1.code_domain = sd0.code_domain
                   AND sd1.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 2
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 2) = 1) sd2
                    ON sd2.code_domain = sd0.code_domain
                   AND sd2.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 3
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 3) = 1) sd3
                    ON sd3.code_domain = sd0.code_domain
                   AND sd3.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 5
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 5) = 1) sd5
                    ON sd5.code_domain = sd0.code_domain
                   AND sd5.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 6
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 6) = 1) sd6
                    ON sd6.code_domain = sd0.code_domain
                   AND sd6.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 7
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 7) = 1) sd7
                    ON sd7.code_domain = sd0.code_domain
                   AND sd7.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 8
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 8) = 1) sd8
                    ON sd8.code_domain = sd0.code_domain
                   AND sd8.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 11
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 11) = 1) sd11
                    ON sd11.code_domain = sd0.code_domain
                   AND sd11.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 12
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 12) = 1) sd12
                    ON sd12.code_domain = sd0.code_domain
                   AND sd12.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 13
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 13) = 1) sd13
                    ON sd13.code_domain = sd0.code_domain
                   AND sd13.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 16
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 16) = 1) sd16
                    ON sd16.code_domain = sd0.code_domain
                   AND sd16.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 17
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 17) = 1) sd17
                    ON sd17.code_domain = sd0.code_domain
                   AND sd17.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 18
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 18) = 1) sd18
                    ON sd18.code_domain = sd0.code_domain
                   AND sd18.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 19
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 19) = 1) sd19
                    ON sd19.code_domain = sd0.code_domain
                   AND sd19.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 20
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 20) = 1) sd20
                    ON sd20.code_domain = sd0.code_domain
                   AND sd20.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 21
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 21) = 1) sd21
                    ON sd21.code_domain = sd0.code_domain
                   AND sd21.val = sd0.val
                  LEFT JOIN (SELECT desc_val, code_domain, val
                              FROM sys_domain
                             WHERE id_language = 22
                               AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT',
                                                                                             'CMT_USERNAME'),
                                                                                 22) = 1) sd22
                    ON sd22.code_domain = sd0.code_domain
                   AND sd22.val = sd0.val)
         WHERE source_language IS NOT NULL) tmp
  JOIN alert_core_data.cmt_translation_tbl_users ttu
    ON tmp.code_translation = ttu.table_name
   AND ttu.trl_owner = 'ALERT_CODES'
   AND ttu.trl_tbl_name = 'ALERT_CODES'
   AND ttu.flg_available = 'Y'
   AND ttu.username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME')
 ORDER BY ttu.id_cmt_translation_tbl_users;
