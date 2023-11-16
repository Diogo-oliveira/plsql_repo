-- CHANGED BY:  Álvaro Vasconcelos
-- CHANGE DATE: 07/09/2011 15:20
-- CHANGE REASON: [ALERT-194276] View and grants for PAT_CHECKLIST table
create or replace view V_PAT_CHECKLIST  as 
  SELECT pc.id_pat_checklist,
         pc.flg_content_creator,
         pc.id_checklist_version,
         pc.id_patient,
         pc.dt_pat_checklist,
         pc.id_professional,
         pc.id_episode_start,
         pc.id_episode_end,
         pc.flg_status,
         pc.flg_progress_status,
         pc.id_prof_cancel,
         pc.dt_cancel_time,
         pc.id_cancel_reason,
         pc.cancel_notes,
         pc.dt_last_update,
         pc.id_prof_last_update
    FROM pat_checklist pc;
    
-- CHANGE END:  Álvaro Vasconcelos