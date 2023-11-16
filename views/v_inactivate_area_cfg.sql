CREATE OR REPLACE VIEW V_INACTIVATE_AREA_CFG AS
SELECT tt.code_task_type, tt.id_task_type_parent, ct.id_record, id_config, ct.id_inst_owner, ct.field_01 active
  FROM config_table ct
 INNER JOIN task_type tt
    ON ct.id_record = tt.id_task_type
 WHERE config_table = 'INACTIVATE_AREAS';
