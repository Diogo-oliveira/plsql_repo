CREATE OR REPLACE VIEW v_automatic_report AS
SELECT ct.id_config     id_config,
       ct.id_inst_owner id_inst_owner,
       ct.id_record     id_reports,
       ct.field_01      screen_name,
       ct.field_02      flg_action
  FROM config_table ct
 WHERE ct.config_table = 'AUTOMATIC_REPORT';
