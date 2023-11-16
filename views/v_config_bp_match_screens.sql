CREATE OR REPLACE VIEW V_CONFIG_BP_MATCH_SCREENS AS
 SELECT *
   FROM (SELECT ct_1.id_config,
                ct_1.id_inst_owner,
                ct_1.field_01 flg_match_begin_trsp,
                ct_2.field_01 flg_revised_begin_trsp,
                ct_1.field_02 flg_match_end_trsp,
                ct_2.field_02 flg_revised_end_trsp,
                ct_1.field_03 flg_match_administer,
                ct_2.field_03 flg_revised_administer,
                c.id_profile_template,
                c.id_software,
                c.id_institution,
                id_market,
                dense_rank() over(PARTITION BY ct_1.id_record, ct_1.id_config ORDER BY ct_1.id_inst_owner DESC, decode(c.id_institution, 0, c.id_market, c.id_institution) DESC, c.id_software DESC) rn
           FROM config_table ct_1
           JOIN alert_core_data.config c
             ON c.id_config = ct_1.id_config
           LEFT JOIN config_table ct_2
             ON ct_2.id_config = ct_1.id_config
            AND ct_2.id_inst_owner = ct_1.id_inst_owner
            AND ct_2.id_record = 2
            AND ct_2.flg_add_remove = ct_1.flg_add_remove
            AND ct_2.config_table = ct_1.config_table
          WHERE ct_1.config_table = 'BP_MATCH_SCREENS'
            AND ct_1.flg_add_remove = 'A'
            AND ct_1.id_record = 1) x_main
  WHERE rn = 1;