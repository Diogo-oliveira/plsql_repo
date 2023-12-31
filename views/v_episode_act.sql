CREATE OR REPLACE VIEW V_EPISODE_ACT AS
SELECT id_visit,
       id_patient,
       id_institution,
       id_episode,
       id_clinical_service,
       dt_begin_tstz_e,
       dt_end_tstz_e,
       flg_status_e,
       id_epis_type,
       companion_e,
       barcode_e,
       id_prof_cancel,
       dt_cancel_tstz,
       flg_type,
       id_prev_episode,
       id_fast_track,
       flg_ehr,
       id_bed,
       id_room,
       id_professional,
       norton,
       flg_hydric,
       flg_wound,
       companion_ei,
       flg_unknown,
       desc_info,
       id_schedule,
       id_first_nurse_resp,
       flg_status_ei,
       id_dep_clin_serv,
       id_first_dep_clin_serv,
       id_department,
       id_software,
       dt_first_obs_tstz,
       dt_first_nurse_obs_tstz,
       id_triage_color,
       triage_acuity,
       triage_color_text,
       triage_rank_acuity,
       triage_flg_letter,
       has_transfer,
       id_announced_arrival,
       dt_begin_tstz
  FROM (SELECT gea.id_visit,
               gea.id_patient,
               gea.id_institution,
               gea.id_episode,
               gea.id_clinical_service,
               gea.dt_begin_tstz           dt_begin_tstz_e,
               gea.dt_end_tstz             dt_end_tstz_e,
               gea.episode_flg_status      flg_status_e,
               gea.id_epis_type,
               gea.episode_companion       companion_e,
               gea.barcode                 barcode_e,
               gea.id_prof_cancel,
               gea.dt_cancel_tstz,
               gea.flg_type,
               gea.id_prev_episode,
               gea.id_fast_track_er_law    id_fast_track,
               gea.flg_ehr,
               gea.id_bed,
               gea.id_room,
               gea.id_professional,
               gea.norton,
               gea.flg_hydric,
               gea.flg_wound,
               gea.epis_info_companion     companion_ei,
               gea.flg_unknown,
               gea.desc_info,
               gea.id_schedule,
               gea.id_first_nurse_resp,
               gea.epis_info_flg_status    flg_status_ei,
               gea.id_dep_clin_serv,
               gea.id_first_dep_clin_serv,
               gea.id_department,
               gea.id_software,
               gea.dt_first_obs_tstz,
               gea.dt_first_nurse_obs_tstz,
               gea.id_triage_color,
               gea.triage_acuity,
               gea.triage_color_text,
               gea.triage_rank_acuity,
               gea.triage_flg_letter,
               gea.flg_has_transfer        has_transfer,
               gea.id_announced_arrival,
               gea.dt_begin_tstz
          FROM grids_ea gea
          JOIN episode e
            ON gea.id_episode = e.id_episode
         WHERE gea.episode_flg_status = 'A'
           AND gea.flg_ehr != 'E'
           AND gea.id_announced_arrival IS NOT NULL
           AND e.flg_status = 'A'
        UNION
        SELECT /*+ use_nl(e ei) index(e epis_search06_idx)*/
         e.id_visit,
         e.id_patient,
         e.id_institution,
         e.id_episode,
         e.id_clinical_service,
         e.dt_begin_tstz dt_begin_tstz_e,
         e.dt_end_tstz dt_end_tstz_e,
         e.flg_status flg_status_e,
         e.id_epis_type,
         e.companion companion_e,
         e.barcode barcode_e,
         e.id_prof_cancel,
         e.dt_cancel_tstz,
         e.flg_type,
         e.id_prev_episode,
         pk_epis_er_law_api.get_fast_track_id(e.id_episode, e.id_fast_track) id_fast_track,
         e.flg_ehr,
         ei.id_bed,
         ei.id_room,
         ei.id_professional,
         ei.norton,
         ei.flg_hydric,
         ei.flg_wound,
         ei.companion companion_ei,
         ei.flg_unknown,
         ei.desc_info,
         ei.id_schedule,
         ei.id_first_nurse_resp,
         ei.flg_status flg_status_ei,
         ei.id_dep_clin_serv,
         ei.id_first_dep_clin_serv,
         e.id_department,
         ei.id_software,
         ei.dt_first_obs_tstz,
         ei.dt_first_nurse_obs_tstz,
         ei.id_triage_color,
         ei.triage_acuity,
         ei.triage_color_text,
         ei.triage_rank_acuity,
         ei.triage_flg_letter,
         pk_transfer_institution.check_epis_transfer(e.id_episode) has_transfer,
         -1 id_announced_arrival,
         e.dt_begin_tstz
          FROM episode e
         INNER JOIN epis_info ei
            ON ei.id_episode = e.id_episode
         WHERE (coalesce(alert_context('l_inactive_cfg'), 'N') = 'Y' AND
               e.dt_end_tstz >
               CAST(current_timestamp - numtodsinterval(coalesce(alert_context('l_time_config'), '24'), 'HOUR') AS
                     TIMESTAMP WITH LOCAL TIME ZONE))
           AND e.flg_ehr != 'E') t
 WHERE t.id_announced_arrival IS NOT NULL;
