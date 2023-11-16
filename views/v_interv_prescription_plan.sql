CREATE OR REPLACE VIEW v_interv_prescription_plan AS
SELECT id_interv_presc_plan,
       id_interv_presc_det,
       id_prof_take,
       notes,
       flg_status,
       id_prof_cancel,
       notes_cancel,
       id_wound_treat,
       id_episode_write,
       dt_plan_tstz,
       dt_take_tstz,
       dt_cancel_tstz,
       id_prof_performed,
       start_time,
       end_time,
       id_schedule_intervention,
       id_change,
       num_exec_sess,
       dt_interv_presc_plan,
       flg_supplies_reg,
       id_cancel_reason,
       id_cdr_event,
       id_epis_documentation,
       exec_number,
       id_prof_last_update,
       dt_last_update_tstz
  FROM interv_presc_plan;
