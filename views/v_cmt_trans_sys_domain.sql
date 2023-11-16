CREATE OR REPLACE VIEW V_CMT_TRANS_SYS_DOMAIN AS
SELECT code_domain,
       val,
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
  FROM (SELECT DISTINCT sd0.code_domain,
                        sd0.val,
                        sd1.desc_val    portuguese_pt,
                        sd2.desc_val    english_us,
                        sd3.desc_val    spanish_es,
                        sd5.desc_val    italian_it,
                        sd6.desc_val    french_fr,
                        sd7.desc_val    english_uk,
                        sd8.desc_val    english_sa,
                        sd11.desc_val   portuguese_br,
                        sd12.desc_val   chinese_zh_cn,
                        sd13.desc_val   chinese_zh_tw,
                        sd16.desc_val   spanish_cl,
                        sd17.desc_val   spanish_mx,
                        sd18.desc_val   french_ch,
                        sd19.desc_val   portuguese_ao,
                        sd20.desc_val   arabic_ar_sa,
                        sd21.desc_val   czech_cz,
                        sd22.desc_val   portuguese_mz
          FROM (SELECT DISTINCT desc_val, code_domain, val
                  FROM sys_domain) sd0
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 1) sd1
            ON sd1.code_domain = sd0.code_domain
           AND sd1.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 2) sd2
            ON sd2.code_domain = sd0.code_domain
           AND sd2.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 3) sd3
            ON sd3.code_domain = sd0.code_domain
           AND sd3.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 5) sd5
            ON sd5.code_domain = sd0.code_domain
           AND sd5.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 6) sd6
            ON sd6.code_domain = sd0.code_domain
           AND sd6.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 7) sd7
            ON sd7.code_domain = sd0.code_domain
           AND sd7.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 8) sd8
            ON sd8.code_domain = sd0.code_domain
           AND sd8.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 11) sd11
            ON sd11.code_domain = sd0.code_domain
           AND sd11.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 12) sd12
            ON sd12.code_domain = sd0.code_domain
           AND sd12.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 13) sd13
            ON sd13.code_domain = sd0.code_domain
           AND sd13.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 16) sd16
            ON sd16.code_domain = sd0.code_domain
           AND sd16.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 17) sd17
            ON sd17.code_domain = sd0.code_domain
           AND sd17.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 18) sd18
            ON sd18.code_domain = sd0.code_domain
           AND sd18.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 19) sd19
            ON sd19.code_domain = sd0.code_domain
           AND sd19.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 20) sd20
            ON sd20.code_domain = sd0.code_domain
           AND sd20.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 21) sd21
            ON sd21.code_domain = sd0.code_domain
           AND sd21.val = sd0.val
          LEFT JOIN (SELECT desc_val, code_domain, val
                      FROM sys_domain
                     WHERE id_language = 22) sd22
            ON sd22.code_domain = sd0.code_domain
           AND sd22.val = sd0.val)
 ORDER BY 1;
