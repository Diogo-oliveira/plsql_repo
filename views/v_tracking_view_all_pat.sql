CREATE OR REPLACE VIEW V_TRACKING_VIEW_ALL_PAT AS
SELECT e.id_episode,
       e.id_visit,
       e.id_patient,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       --
       e.dt_begin_tstz,
       ei.id_professional,
       e.id_institution,
       ei.dt_first_obs_tstz,
       e.id_epis_type,
       e.id_department,
       ei.id_software,
       ei.id_disch_reas_dest,
       ei.flg_dsch_status,
       tbea.flg_has_stripes,
       tbea.id_nurse_resp,
       tbea.id_prof_resp,
       tbea.id_fast_track,
       tbea.id_triage_color,
       tbea.rowid rowid_tbea,
       tbea.transp_delay,
       tbea.transp_ongoing,
       tbea.dt_begin,
       --
       bd.desc_bed,
       bd.code_bed,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.desc_room,
       ei.id_room,
       ei.triage_acuity,
       ei.triage_color_text,
       ei.triage_rank_acuity,
       ei.triage_flg_letter,
       --
       aw.flg_interv_prescription,
       aw.flg_nurse_activity_req,
       gt.monitorization,
       gt.drug_presc
  FROM tracking_board_ea tbea
  JOIN episode e
    ON e.id_episode = tbea.id_episode
  JOIN epis_info ei
    ON ei.id_episode = tbea.id_episode
  JOIN patient pat
    ON pat.id_patient = tbea.id_patient
  JOIN awareness aw
    ON aw.id_patient = tbea.id_patient
   AND aw.id_episode = tbea.id_episode
  LEFT JOIN grid_task gt
    ON e.id_episode = gt.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = tbea.id_bed
  LEFT JOIN room ro
    ON ro.id_room = tbea.id_room
 WHERE tbea.id_epis_type = 2
   AND ei.id_room <> sys_context('ALERT_CONTEXT', 'l_temp_room')
   AND (sys_context('ALERT_CONTEXT', 'i_id_room') IS NULL OR ei.id_room = sys_context('ALERT_CONTEXT', 'i_id_room'));
