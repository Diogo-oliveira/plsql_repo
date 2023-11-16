CREATE OR REPLACE VIEW V_CMT_TRANS_SYS_MESSAGE AS
WITH tmp_tbl AS
 (SELECT DISTINCT desc_message, code_message, id_software, module, id_market, id_institution
    FROM sys_message
   WHERE id_institution = 0
     AND id_market = 0
     AND code_message NOT LIKE 'APEX%')

SELECT DISTINCT sd0.code_message,
                initcap((SELECT pk_translation.get_translation(2, code_software)
                          FROM alert.software
                         WHERE id_software = sd0.id_software)) AS software,
                sd0.module,
                sd1.desc_message portuguese_pt,
                sd11.desc_message portuguese_br,
                sd19.desc_message portuguese_ao,
                sd22.desc_message portuguese_mz,
                sd2.desc_message english_us,
                sd7.desc_message english_uk,
                sd8.desc_message english_sa,
                sd3.desc_message spanish_es,
                sd16.desc_message spanish_cl,
                sd17.desc_message spanish_mx,
                sd6.desc_message french_fr,
                sd18.desc_message french_ch,
                sd5.desc_message italian_it,
                sd12.desc_message chinese_zh_cn,
                sd13.desc_message chinese_zh_tw,
                sd21.desc_message czech_cz,
                sd20.desc_message arabic_ar_sa
  FROM tmp_tbl sd0
  LEFT JOIN (SELECT desc_message, code_message, id_software, id_institution, module, id_market
               FROM sys_message
              WHERE id_language = 1) sd1
    ON sd1.code_message = sd0.code_message
   AND sd1.id_software = sd0.id_software
   AND sd1.id_institution = sd0.id_institution
   AND sd1.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 2) sd2
    ON sd2.code_message = sd0.code_message
   AND sd2.id_software = sd0.id_software
   AND sd2.id_institution = sd0.id_institution
   AND sd2.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 3) sd3
    ON sd3.code_message = sd0.code_message
   AND sd3.id_software = sd0.id_software
   AND sd3.id_institution = sd0.id_institution
   AND sd3.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 5) sd5
    ON sd5.code_message = sd0.code_message
   AND sd5.id_software = sd0.id_software
   AND sd5.id_institution = sd0.id_institution
   AND sd5.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 6) sd6
    ON sd6.code_message = sd0.code_message
   AND sd6.id_software = sd0.id_software
   AND sd6.id_institution = sd0.id_institution
   AND sd6.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 7) sd7
    ON sd7.code_message = sd0.code_message
   AND sd7.id_software = sd0.id_software
   AND sd7.id_institution = sd0.id_institution
   AND sd7.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 8) sd8
    ON sd8.code_message = sd0.code_message
   AND sd8.id_software = sd0.id_software
   AND sd8.id_institution = sd0.id_institution
   AND sd8.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 11) sd11
    ON sd11.code_message = sd0.code_message
   AND sd11.id_software = sd0.id_software
   AND sd11.id_institution = sd0.id_institution
   AND sd11.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 12) sd12
    ON sd12.code_message = sd0.code_message
   AND sd12.id_software = sd0.id_software
   AND sd12.id_institution = sd0.id_institution
   AND sd12.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 13) sd13
    ON sd13.code_message = sd0.code_message
   AND sd13.id_software = sd0.id_software
   AND sd13.id_institution = sd0.id_institution
   AND sd13.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 16) sd16
    ON sd16.code_message = sd0.code_message
   AND sd16.id_software = sd0.id_software
   AND sd16.id_institution = sd0.id_institution
   AND sd16.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 17) sd17
    ON sd17.code_message = sd0.code_message
   AND sd17.id_software = sd0.id_software
   AND sd17.id_institution = sd0.id_institution
   AND sd17.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 18) sd18
    ON sd18.code_message = sd0.code_message
   AND sd18.id_software = sd0.id_software
   AND sd18.id_institution = sd0.id_institution
   AND sd18.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 19) sd19
    ON sd19.code_message = sd0.code_message
   AND sd19.id_software = sd0.id_software
   AND sd19.id_institution = sd0.id_institution
   AND sd19.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 20) sd20
    ON sd20.code_message = sd0.code_message
   AND sd20.id_software = sd0.id_software
   AND sd20.id_institution = sd0.id_institution
   AND sd20.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 21) sd21
    ON sd21.code_message = sd0.code_message
   AND sd21.id_software = sd0.id_software
   AND sd21.id_institution = sd0.id_institution
   AND sd21.id_market = sd0.id_market
  LEFT JOIN (SELECT desc_message, code_message, id_software, module, id_institution, id_market
               FROM sys_message
              WHERE id_language = 22) sd22
    ON sd22.code_message = sd0.code_message
   AND sd22.id_software = sd0.id_software
   AND sd22.id_institution = sd0.id_institution
   AND sd22.id_market = sd0.id_market;
