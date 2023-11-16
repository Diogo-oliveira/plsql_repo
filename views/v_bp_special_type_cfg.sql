CREATE OR REPLACE VIEW V_BP_SPECIAL_TYPE_CFG AS
SELECT ct.id_config              id_config,
       ct.id_inst_owner          id_inst_owner,
       ct.field_01               id_hemo_type,
       ct.field_02               priority_val,
       ct.field_05               age_min,
       ct.field_06               age_min_format,
       ct.field_07               age_max,
       ct.field_08               age_max_format,
       sd.desc_val               priority_desc,
       sd.id_language            priority_lang,
       mch.id_multichoice_option,
       mch.desc_option,
       mch.rank
  FROM config_table ct
  JOIN sys_domain sd
    ON sd.val = ct.field_02
  JOIN (SELECT t.id_multichoice_option, t.desc_option, t.rank
          FROM TABLE(pk_multichoice.tf_multichoice_options(i_lang             => alert_context('i_lang'),
                                                           i_prof             => profissional(alert_context('i_prof_id'),
                                                                                              alert_context('i_institution'),
                                                                                              alert_context('i_software')),
                                                           i_multichoice_type => 'BLOOD_PRODUCT_DET.PRIORITY.URGENT')) t) mch
    ON mch.id_multichoice_option = ct.field_03
 WHERE ct.config_table = 'BP_SPECIAL_TYPE'
   AND sd.code_domain = 'BLOOD_PRODUCT_DET.FLG_PRIORITY'
   AND sd.val = 'U'
   AND ct.field_04 = 'Y'
UNION ALL
SELECT ct.id_config              id_config,
       ct.id_inst_owner          id_inst_owner,
       ct.field_01               id_hemo_type,
       ct.field_02               priority_val,
       ct.field_05               age_min,
       ct.field_06               age_min_format,
       ct.field_07               age_max,
       ct.field_08               age_max_format,
       sd.desc_val               priority_desc,
       sd.id_language            priority_lang,
       mch.id_multichoice_option,
       mch.desc_option,
       mch.rank
  FROM config_table ct
  JOIN sys_domain sd
    ON sd.val = ct.field_02
  JOIN (SELECT t.id_multichoice_option, t.desc_option, t.rank
          FROM TABLE(pk_multichoice.tf_multichoice_options(i_lang             => alert_context('i_lang'),
                                                           i_prof             => profissional(alert_context('i_prof_id'),
                                                                                              alert_context('i_institution'),
                                                                                              alert_context('i_software')),
                                                           i_multichoice_type => 'BLOOD_PRODUCT_DET.PRIORITY.EMERGENCY')) t) mch
    ON mch.id_multichoice_option = ct.field_03
 WHERE ct.config_table = 'BP_SPECIAL_TYPE'
   AND sd.code_domain = 'BLOOD_PRODUCT_DET.FLG_PRIORITY'
   AND sd.val = 'E'
   AND ct.field_04 = 'Y'
UNION ALL
SELECT ct.id_config              id_config,
       ct.id_inst_owner          id_inst_owner,
       ct.field_01               id_hemo_type,
       ct.field_02               priority_val,
       ct.field_05               age_min,
       ct.field_06               age_min_format,
       ct.field_07               age_max,
       ct.field_08               age_max_format,
       sd.desc_val               priority_desc,
       sd.id_language            priority_lang,
       mch.id_multichoice_option,
       mch.desc_option,
       mch.rank
  FROM config_table ct
  JOIN sys_domain sd
    ON sd.val = ct.field_02
  JOIN (SELECT t.id_multichoice_option, t.desc_option, t.rank
          FROM TABLE(pk_multichoice.tf_multichoice_options(i_lang             => alert_context('i_lang'),
                                                           i_prof             => profissional(alert_context('i_prof_id'),
                                                                                              alert_context('i_institution'),
                                                                                              alert_context('i_software')),
                                                           i_multichoice_type => 'BLOOD_PRODUCT_DET.PRIORITY.ROUTINE')) t) mch
    ON mch.id_multichoice_option = ct.field_03
 WHERE ct.config_table = 'BP_SPECIAL_TYPE'
   AND sd.code_domain = 'BLOOD_PRODUCT_DET.FLG_PRIORITY'
   AND sd.val = 'N'
   AND ct.field_04 = 'Y';