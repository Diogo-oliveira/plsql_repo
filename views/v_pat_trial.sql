create or replace view v_pat_trial as
SELECT id_pat_trial,
       id_patient,
       id_trial,
       dt_record,
       id_prof_record,
       dt_trial_begin,
       flg_status,
       dt_start,
       dt_end,
       id_institution,
       id_cancel_info_det,
       id_episode
  FROM pat_trial;
/
