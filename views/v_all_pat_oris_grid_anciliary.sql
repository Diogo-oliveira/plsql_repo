CREATE OR REPLACE VIEW V_ALL_PAT_ORIS_GRID_ANCILIARY AS
SELECT e.id_episode,
       e.id_visit,
       e.id_patient,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       --
       s.id_schedule,
       s.dt_interv_preview_tstz,
       s.dt_target_tstz,
       s.flg_status flg_surg_status,
       s.id_institution,
       e.flg_ehr,
       --
       ro.id_room,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.desc_room,
       srr.flg_status            flg_status_room,
       srr.dt_status_tstz        dt_room,
       --
       v_s_aux.id_instit_requested,
       v_s_aux.id_software,
       v_s_aux.desc_cli_rec_req,
       v_s_aux.desc_drug_req,
       v_s_aux.desc_mov,
       v_s_aux.desc_harvest,
       gt.hemo_req,
       gt.supplies
  FROM schedule_sr s
  JOIN episode e
    ON e.id_episode = s.id_episode
  JOIN patient pat
    ON pat.id_patient = s.id_patient
  LEFT JOIN v_sr_grid_aux_schedule v_s_aux
    ON (v_s_aux.id_episode = s.id_episode AND v_s_aux.id_software = sys_context('ALERT_CONTEXT', 'i_software'))
  LEFT JOIN room_scheduled sr
    ON sr.id_schedule = s.id_schedule
  LEFT JOIN room ro
    ON ro.id_room = sr.id_room
  LEFT JOIN sr_room_status srr
    ON srr.id_room = ro.id_room
  JOIN grid_task gt
    ON gt.id_episode = e.id_episode
 WHERE (sr.id_room_scheduled = pk_sr_grid.get_last_room_status(s.id_schedule, 'S') OR sr.id_room_scheduled IS NULL)
   AND (srr.id_sr_room_state = pk_sr_grid.get_last_room_status(srr.id_room, 'R') OR srr.id_sr_room_state IS NULL);
