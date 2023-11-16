CREATE OR REPLACE VIEW V_MY_PAT_EDIS_GRID_ANCILIARY AS
SELECT e.id_episode,
       e.id_visit,
       e.id_patient,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       e.id_first_nurse_resp,
       e.id_professional,
       e.id_institution,
       e.dt_begin_tstz,
       e.dt_begin_tstz_e,
       e.id_epis_type,
       e.flg_ehr,
       e.dt_first_obs_tstz,
       --
       e.triage_acuity,
       e.triage_color_text,
       e.triage_rank_acuity,
       e.triage_flg_letter,
       e.id_fast_track,
       e.id_triage_color,
       e.has_transfer,
       --
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.rank room_rank,
       ro.desc_room,
       --
       gt.drug_transp,
       gt.movement,
       gt.hemo_req,
       gt.supplies
  FROM v_episode_act e
  JOIN patient pat
    ON e.id_patient = pat.id_patient
  JOIN grid_task gt
    ON e.id_episode = gt.id_episode
  LEFT JOIN room ro
    ON e.id_room = ro.id_room
 WHERE (sys_context('ALERT_CONTEXT', 'g_show_all') = 'Y' OR EXISTS
        (SELECT 1
           FROM grid_task gt
          WHERE gt.id_episode = e.id_episode
            AND coalesce(gt.movement, gt.harvest, gt.drug_transp) IS NOT NULL))
   AND e.id_software = sys_context('ALERT_CONTEXT', 'i_software')
   AND EXISTS (SELECT 0
          FROM prof_room pr
         WHERE pr.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND e.id_room = pr.id_room)
--
UNION ALL
SELECT e.id_episode,
       e.id_visit,
       e.id_patient,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       e.id_first_nurse_resp,
       e.id_professional,
       e.id_institution,
       e.dt_begin_tstz,
       e.dt_begin_tstz_e,
       e.id_epis_type,
       e.flg_ehr,
       e.dt_first_obs_tstz,
       --
       e.triage_acuity,
       e.triage_color_text,
       e.triage_rank_acuity,
       e.triage_flg_letter,
       e.id_fast_track,
       e.id_triage_color,
       e.has_transfer,
       --
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.rank room_rank,
       ro.desc_room,
       --
       gt.drug_transp,
       gt.movement,
       gt.hemo_req,
       gt.supplies
  FROM v_episode_act e
  JOIN patient pat
    ON e.id_patient = pat.id_patient
  JOIN grid_task gt
    ON e.id_episode = gt.id_episode
  LEFT JOIN room ro
    ON e.id_room = ro.id_room
 WHERE (sys_context('ALERT_CONTEXT', 'g_show_all') = 'Y' OR EXISTS
        (SELECT 1
           FROM grid_task gt
          WHERE gt.id_episode = e.id_episode
            AND coalesce(gt.movement, gt.harvest, gt.drug_transp) IS NOT NULL))
   AND pk_episode.get_soft_by_epis_type(e.id_epis_type, sys_context('ALERT_CONTEXT', 'i_institution')) =
       sys_context('ALERT_CONTEXT', 'g_id_software_inp')
   AND EXISTS
 (SELECT 1
          FROM episode epis, discharge d
         WHERE epis.id_episode = d.id_episode
           AND epis.id_episode = e.id_prev_episode
           AND d.flg_status IN ('A', 'P')
           AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, sys_context('ALERT_CONTEXT', 'i_institution')) =
               sys_context('ALERT_CONTEXT', 'i_software')
           AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND epis.flg_ehr = 'N')
   AND nvl(sys_context('ALERT_CONTEXT', 'g_show_inp_epis'), 'Y') = 'Y'
   AND EXISTS (SELECT 0
          FROM prof_room pr
         WHERE pr.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND e.id_room = pr.id_room);
