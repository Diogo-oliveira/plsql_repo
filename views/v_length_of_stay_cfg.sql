CREATE OR REPLACE VIEW V_LENGTH_OF_STAY_CFG AS
SELECT los.id_length_of_stay id_length_of_stay,
       los.id_color          id_color,
       ct.id_config          id_config,
       ct.id_inst_owner      id_inst_owner,
       ct.field_01           min_val,
       ct.field_02           max_val,
       ct.field_03           order_rank,
       ct.field_04           breach
  FROM alert_core_data.config_table ct
  JOIN length_of_stay los
    ON los.id_length_of_stay = ct.id_record
 WHERE ct.config_table = 'LENGTH_OF_STAY';
