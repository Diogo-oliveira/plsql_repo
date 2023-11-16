-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 23/03/2010 11:12
-- CHANGE REASON: [ALERT-82859] Versioning of views for Java Entities generation
CREATE OR REPLACE view v_schedule_sr AS
SELECT id_schedule_sr,
       id_sched_sr_parent,
       id_schedule,
       id_episode,
       id_patient,
       duration,
       id_diagnosis,
       id_speciality,
       flg_status,
       flg_sched,
       id_dept_dest,
       prev_recovery_time,
       id_sr_cancel_reason,
       id_prof_cancel,
       notes_cancel,
       id_prof_reg,
       id_institution,
       adw_last_update,
       dt_target_tstz,
       dt_interv_preview_tstz,
       dt_cancel_tstz,
       id_waiting_list,
       flg_temporary,
       icu,
       notes,
       adm_needed
  FROM schedule_sr;
-- CHANGE END: Gustavo Serrano