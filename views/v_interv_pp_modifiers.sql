CREATE OR REPLACE VIEW v_interv_pp_modifiers AS
SELECT ipm.id_interv_pp_modifiers,
       ipm.id_interv_presc_plan,
       ipm.id_modifier,
       ipm.id_inst_owner,
       ipm.id_prof_last_update,
       ipm.dt_last_update_tstz
  FROM interv_pp_modifiers ipm;