CREATE OR REPLACE VIEW v_viewer_checklist_cfg AS
SELECT ci.id_viewer_checklist_item id_record,
       ci.id_viewer_item           id_viewer_item,
       vi.item_internal_name       item_internal_name,
       ci.id_viewer_checklist      id_viewer_checklist,
       vc.checklist_internal_name  chklist_internal_name,
       vi.execute_api              execute_api,
       ct.id_config                id_config,
       ct.id_inst_owner            id_inst_owner,
       ct.field_01                 flg_scope_type,
       ct.field_02                 desc_alt,
       ct.field_03                 order_rank
  FROM alert_core_data.config_table ct
  JOIN viewer_checklist_item ci
    ON ci.id_viewer_checklist_item = ct.id_record
  JOIN viewer_item vi
    ON vi.id_viewer_item = ci.id_viewer_item
  JOIN viewer_checklist vc
    ON vc.id_viewer_checklist = ci.id_viewer_checklist
 WHERE ct.config_table = 'VIEWER_CHECKLIST';
