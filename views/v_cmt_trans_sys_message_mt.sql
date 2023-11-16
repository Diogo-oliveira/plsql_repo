CREATE OR REPLACE VIEW V_CMT_TRANS_SYS_MESSAGE_MT AS
WITH tmp_tbl AS
 (SELECT DISTINCT desc_message, code_message, id_software, module, id_market, id_institution
    FROM sys_message
   WHERE id_institution = 0
     AND id_market = 0
     AND code_message NOT LIKE 'APEX%'
     AND id_language = alert.pk_cmt_content_core.get_source_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'))
     AND desc_message IS NOT NULL
     AND desc_message != ' ')

SELECT code_message,
       software,
       module,
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
  FROM (SELECT DISTINCT sd0.code_message,
                        initcap((SELECT pk_translation.get_translation(2, code_software)
                                  FROM alert.software
                                 WHERE id_software = sd0.id_software)) AS software,
                        sd0.module,
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
          FROM tmp_tbl sd0
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 1
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 1) = 1) sd1
            ON sd0.code_message = sd1.code_message
           AND sd0.id_software = sd1.id_software
           AND sd0.id_institution = sd1.id_institution
           AND sd0.id_market = sd1.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 2
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 2) = 1) sd2
            ON sd0.code_message = sd2.code_message
           AND sd0.id_software = sd2.id_software
           AND sd0.id_institution = sd2.id_institution
           AND sd0.id_market = sd2.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 3
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 3) = 1) sd3
            ON sd0.code_message = sd3.code_message
           AND sd0.id_software = sd3.id_software
           AND sd0.id_institution = sd3.id_institution
           AND sd0.id_market = sd3.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 5
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 5) = 1) sd5
            ON sd0.code_message = sd5.code_message
           AND sd0.id_software = sd5.id_software
           AND sd0.id_institution = sd5.id_institution
           AND sd0.id_market = sd5.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 6
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 6) = 1) sd6
            ON sd0.code_message = sd6.code_message
           AND sd0.id_software = sd6.id_software
           AND sd0.id_institution = sd6.id_institution
           AND sd0.id_market = sd6.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 7
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 7) = 1) sd7
            ON sd0.code_message = sd7.code_message
           AND sd0.id_software = sd7.id_software
           AND sd0.id_institution = sd7.id_institution
           AND sd0.id_market = sd7.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 8
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 8) = 1) sd8
            ON sd0.code_message = sd8.code_message
           AND sd0.id_software = sd8.id_software
           AND sd0.id_institution = sd8.id_institution
           AND sd0.id_market = sd8.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 9
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 9) = 1) sd9
            ON sd0.code_message = sd9.code_message
           AND sd0.id_software = sd9.id_software
           AND sd0.id_institution = sd9.id_institution
           AND sd0.id_market = sd9.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 11
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         11) = 1) sd11
            ON sd0.code_message = sd11.code_message
           AND sd0.id_software = sd11.id_software
           AND sd0.id_institution = sd11.id_institution
           AND sd0.id_market = sd11.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 12
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         12) = 1) sd12
            ON sd0.code_message = sd12.code_message
           AND sd0.id_software = sd12.id_software
           AND sd0.id_institution = sd12.id_institution
           AND sd0.id_market = sd12.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 13
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         13) = 1) sd13
            ON sd0.code_message = sd13.code_message
           AND sd0.id_software = sd13.id_software
           AND sd0.id_institution = sd13.id_institution
           AND sd0.id_market = sd13.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 16
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         16) = 1) sd16
            ON sd0.code_message = sd16.code_message
           AND sd0.id_software = sd16.id_software
           AND sd0.id_institution = sd16.id_institution
           AND sd0.id_market = sd16.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 17
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         17) = 1) sd17
            ON sd0.code_message = sd17.code_message
           AND sd0.id_software = sd17.id_software
           AND sd0.id_institution = sd17.id_institution
           AND sd0.id_market = sd17.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 18
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         18) = 1) sd18
            ON sd0.code_message = sd18.code_message
           AND sd0.id_software = sd18.id_software
           AND sd0.id_institution = sd18.id_institution
           AND sd0.id_market = sd18.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 19
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         19) = 1) sd19
            ON sd0.code_message = sd19.code_message
           AND sd0.id_software = sd19.id_software
           AND sd0.id_institution = sd19.id_institution
           AND sd0.id_market = sd19.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 20
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         20) = 1) sd20
            ON sd0.code_message = sd20.code_message
           AND sd0.id_software = sd20.id_software
           AND sd0.id_institution = sd20.id_institution
           AND sd0.id_market = sd20.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 21
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         21) = 1) sd21
            ON sd0.code_message = sd21.code_message
           AND sd0.id_software = sd21.id_software
           AND sd0.id_institution = sd21.id_institution
           AND sd0.id_market = sd21.id_market
          LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_market, id_institution
                      FROM sys_message
                     WHERE id_language = 22
                       AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'),
                                                                         22) = 1) sd22
            ON sd0.code_message = sd22.code_message
           AND sd0.id_software = sd22.id_software
           AND sd0.id_institution = sd22.id_institution
           AND sd0.id_market = sd22.id_market)
 ORDER BY 4 DESC;
