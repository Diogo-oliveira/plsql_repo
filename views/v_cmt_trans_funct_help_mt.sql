CREATE OR REPLACE VIEW V_CMT_TRANS_FUNCT_HELP_MT AS
SELECT sd0.id_software AS id_software,
       initcap(pk_translation.get_translation(2, s.code_software)) AS software_desc,
       sd0.code_help,
       sd0.desc_help source_language,
       sd1.desc_help portuguese_pt,
       sd11.desc_help portuguese_br,
       sd19.desc_help portuguese_ao,
       sd22.desc_help portuguese_mz,
       sd2.desc_help english_us,
       sd7.desc_help english_uk,
       sd8.desc_help english_sa,
       sd3.desc_help spanish_es,
       sd16.desc_help spanish_cl,
       sd17.desc_help spanish_mx,
       sd6.desc_help french_fr,
       sd18.desc_help french_ch,
       sd5.desc_help italian_it,
       sd12.desc_help chinese_zh_cn,
       sd13.desc_help chinese_zh_tw,
       sd21.desc_help czech_cz,
       sd20.desc_help arabic_ar_sa
  FROM (SELECT code_help, id_software, desc_help
          FROM functionality_help
         WHERE flg_available = 'Y'
           AND id_language = alert.pk_cmt_content_core.get_source_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'))) sd0
  LEFT JOIN alert.software s
    ON s.id_software = sd0.id_software
  LEFT JOIN functionality_help sd1
    ON sd1.code_help = sd0.code_help
   AND sd1.id_software = sd0.id_software
   AND sd1.id_language = 1
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 1) = 1
  LEFT JOIN functionality_help sd2
    ON sd2.code_help = sd0.code_help
   AND sd2.id_software = sd0.id_software
   AND sd2.id_language = 2
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 2) = 1
  LEFT JOIN functionality_help sd3
    ON sd3.code_help = sd0.code_help
   AND sd3.id_software = sd0.id_software
   AND sd3.id_language = 3
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 3) = 1
  LEFT JOIN functionality_help sd5
    ON sd5.code_help = sd0.code_help
   AND sd5.id_software = sd0.id_software
   AND sd5.id_language = 5
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 5) = 1
  LEFT JOIN functionality_help sd6
    ON sd6.code_help = sd0.code_help
   AND sd6.id_software = sd0.id_software
   AND sd6.id_language = 6
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 6) = 1
  LEFT JOIN functionality_help sd7
    ON sd7.code_help = sd0.code_help
   AND sd7.id_software = sd0.id_software
   AND sd7.id_language = 7
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 7) = 1
  LEFT JOIN functionality_help sd8
    ON sd8.code_help = sd0.code_help
   AND sd8.id_software = sd0.id_software
   AND sd8.id_language = 8
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 8) = 1
  LEFT JOIN functionality_help sd11
    ON sd11.code_help = sd0.code_help
   AND sd11.id_software = sd0.id_software
   AND sd11.id_language = 11
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 11) = 1
  LEFT JOIN functionality_help sd12
    ON sd12.code_help = sd0.code_help
   AND sd12.id_software = sd0.id_software
   AND sd12.id_language = 12
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 12) = 1
  LEFT JOIN functionality_help sd13
    ON sd13.code_help = sd0.code_help
   AND sd13.id_software = sd0.id_software
   AND sd13.id_language = 13
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 13) = 1
  LEFT JOIN functionality_help sd16
    ON sd16.code_help = sd0.code_help
   AND sd16.id_software = sd0.id_software
   AND sd16.id_language = 16
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 16) = 1
  LEFT JOIN functionality_help sd17
    ON sd17.code_help = sd0.code_help
   AND sd17.id_software = sd0.id_software
   AND sd17.id_language = 17
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 17) = 1
  LEFT JOIN functionality_help sd18
    ON sd18.code_help = sd0.code_help
   AND sd18.id_software = sd0.id_software
   AND sd18.id_language = 18
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 18) = 1
  LEFT JOIN functionality_help sd19
    ON sd19.code_help = sd0.code_help
   AND sd19.id_software = sd0.id_software
   AND sd19.id_language = 19
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 19) = 1
  LEFT JOIN functionality_help sd20
    ON sd20.code_help = sd0.code_help
   AND sd20.id_software = sd0.id_software
   AND sd20.id_language = 20
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 20) = 1
  LEFT JOIN functionality_help sd21
    ON sd21.code_help = sd0.code_help
   AND sd21.id_software = sd0.id_software
   AND sd21.id_language = 21
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 21) = 1
  LEFT JOIN functionality_help sd22
    ON sd22.code_help = sd0.code_help
   AND sd22.id_software = sd0.id_software
   AND sd22.id_language = 22
   AND alert.pk_cmt_content_core.check_dest_language(sys_context('ALERT_CONTEXT', 'CMT_USERNAME'), 22) = 1;
