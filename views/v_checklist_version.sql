-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 24/06/2010 15:14
-- CHANGE REASON: [ALERT-70633] Checklists: Back Office & Front Office (DDL)
CREATE OR REPLACE view v_checklist_version AS
    SELECT flg_content_creator,
           internal_name,
           version,
           id_checklist_version,
           id_checklist,
           dt_checklist_version,
           flg_type,
           name,
           code_name,
           flg_use_translation,
           id_professional,
           ROWID row_id
      FROM checklist_version chkv
     WHERE chkv.dt_retire_time IS NULL;
-- CHANGE END: Ariel Machado