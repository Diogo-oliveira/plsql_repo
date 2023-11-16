-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 24/06/2010 15:14
-- CHANGE REASON: [ALERT-70633] Checklists: Back Office & Front Office (DDL)
CREATE OR REPLACE view v_pat_checklist_det AS
    SELECT id_pat_checklist,
           flg_content_creator,
           id_checklist_item,
           id_episode,
           id_professional,
           flg_answer,
           dt_pat_checklist_det,
           notes,
           del_status,
           ROWID row_id
      FROM pat_checklist_det pchkd
     WHERE pchkd.dt_retire_time IS NULL;
-- CHANGE END: Ariel Machado