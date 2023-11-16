CREATE OR REPLACE VIEW V_SR_PROF_TEAM_DET AS  
SELECT id_sr_prof_team_det,
       id_surgery_record,
       id_episode,
       id_prof_team_leader,
       id_professional,
       adw_last_update,
       id_category_sub,
       id_prof_team,
       flg_status,
       id_prof_reg,
       id_prof_cancel,
       dt_begin_tstz,
       dt_end_tstz,
       dt_reg_tstz,
       dt_cancel_tstz,
       id_episode_context,
       id_sr_epis_interv
  FROM sr_prof_team_det;