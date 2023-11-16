-- CHANGED BY:  tiago.pereira
-- CHANGE DATE: 23/03/2015
-- CHANGE REASON: [ALERT-307852] 

CREATE OR REPLACE VIEW ALERT.V_REP_CONFIG_TABLE AS
SELECT config_table,
       id_record,
       id_config,
       flg_add_remove,
       flg_original,
       id_inst_owner,
       field_01 AS ID_REP_GROUP_LOGOS,
       field_02,
       field_03,
       field_04,
       field_05,
       field_06,
       field_07,
       field_08,
       field_09,
       field_10,
       field_11,
       field_12,
       field_13,
       field_14,
       field_15,
       field_16,
       field_17,
       field_18,
       field_19
  FROM V_CONFIG_TABLE T
  WHERE T.CONFIG_TABLE = 'REP_GROUP_LOGOS';

 --CHANGE END