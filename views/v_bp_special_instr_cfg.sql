CREATE OR REPLACE view V_BP_SPECIAL_INSTR_CFG AS
SELECT ct.id_config              id_config,
       ct.id_inst_owner          id_inst_owner,
       ct.field_01               id_hemo_type,
       ct.field_02               priority_val,
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
                                                           i_multichoice_type => 'BLOOD_PRODUCT_DET.SPECIAL_INSTR')) t) mch
    ON mch.id_multichoice_option = ct.field_03
 WHERE ct.config_table = 'BP_SPECIAL_INSTRUCTIONS'
   AND sd.code_domain = 'BLOOD_PRODUCT_DET.FLG_PRIORITY'
	 AND ct.field_04 = 'Y';
