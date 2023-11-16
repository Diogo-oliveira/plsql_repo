--V_MY_PATIENTS_INP_GRID
CREATE OR REPLACE VIEW V_MY_PATIENTS_INP_GRID AS
SELECT gea.id_episode,
       gea.id_visit,
       gea.id_patient,
       gea.episode_flg_status flg_status_e,
       gea.id_first_nurse_resp,
       gea.id_professional,
       gea.id_institution,
       gea.dt_begin_tstz,
       gea.dt_cancel_tstz,
       bd.id_bed,
       bd.desc_bed,
       bd.code_bed,
       bd.rank bed_rank,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.rank room_rank,
       ro.desc_room,
       dpt.abbreviation,
       dpt.code_department,
       dpt.rank dep_rank,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       gea.dt_first_obs_tstz,
       nvl2(bd.id_bed, 1, 0) allocated,
       0 status_rank,
       gea.epis_info_flg_status flg_status_ei,
       dch.flg_status flg_disch_status,
       nvl(dch.dt_med_tstz, dch.dt_admin_tstz) dt_med_tstz,
       gea.id_clinical_service,
       pat.identity_code,
       gea.dt_begin_tstz dt_admission,
       gea.flg_ehr,
       gea.id_epis_type,
       gea.id_prev_episode
  FROM grids_ea gea
 INNER JOIN patient pat
    ON gea.id_patient = pat.id_patient
  LEFT OUTER JOIN bed bd
    ON gea.id_bed = bd.id_bed
  LEFT OUTER JOIN room ro
    ON bd.id_room = ro.id_room
  LEFT OUTER JOIN department dpt
    ON ro.id_department = dpt.id_department
  LEFT OUTER JOIN discharge dch
    ON (dch.id_episode = gea.id_episode AND dch.flg_status IN ('A', 'P'))
  LEFT OUTER JOIN discharge_schedule ds
    ON ds.id_episode = gea.id_episode
   AND ds.id_patient = pat.id_patient
   AND ds.flg_status = 'Y'
 WHERE gea.episode_flg_status <> 'C'
   AND gea.id_announced_arrival IS NOT NULL
   AND gea.id_epis_type = 5
   AND gea.flg_ehr = 'N'
UNION ALL
SELECT e.id_episode,
       e.id_visit,
       e.id_patient,
       e.flg_status flg_status_e,
       ei.id_first_nurse_resp,
       ei.id_professional,
       e.id_institution,
       e.dt_begin_tstz,
       e.dt_cancel_tstz,
       bd.id_bed,
       bd.desc_bed,
       bd.code_bed,
       bd.rank bed_rank,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.rank room_rank,
       ro.desc_room,
       dpt.abbreviation,
       dpt.code_department,
       dpt.rank dep_rank,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       ei.dt_first_obs_tstz,
       nvl2(bd.id_bed, 1, 0) allocated,
       0 status_rank,
       ei.flg_status flg_status_ei,
       dch.flg_status flg_disch_status,
       nvl(dch.dt_med_tstz, dch.dt_admin_tstz) dt_med_tstz,
       e.id_clinical_service,
       pat.identity_code,
       e.dt_begin_tstz dt_admission,
       e.flg_Ehr,
       e.id_epis_type,
       e.id_prev_episode
  FROM episode e
  JOIN epis_info ei
    ON e.id_episode = ei.id_episode
 INNER JOIN patient pat
    ON e.id_patient = pat.id_patient
  LEFT OUTER JOIN bed bd
    ON ei.id_bed = bd.id_bed
  LEFT OUTER JOIN room ro
    ON bd.id_room = ro.id_room
  LEFT OUTER JOIN department dpt
    ON ro.id_department = dpt.id_department
  LEFT OUTER JOIN discharge dch
    ON (dch.id_episode = e.id_episode AND dch.flg_status IN ('A', 'P'))
  LEFT OUTER JOIN discharge_schedule ds
    ON ds.id_episode = e.id_episode
   AND ds.id_patient = pat.id_patient
   AND ds.flg_status = 'Y'
 WHERE e.flg_status = 'I'
   AND e.id_epis_type = 5
   AND e.flg_ehr = 'N'
UNION ALL
SELECT epis.id_episode,
       epis.id_visit,
       epis.id_patient,
       epis.flg_status          flg_status_e,
       ei.id_first_nurse_resp,
       ei.id_professional,
       epis.id_institution,
       epis.dt_begin_tstz,
       epis.dt_cancel_tstz,
       NULL                     id_bed,
       NULL                     desc_bed,
       NULL                     code_bed,
       NULL                     bed_rank,
       NULL                     desc_room_abbreviation,
       NULL                     code_abbreviation,
       NULL                     code_room,
       NULL                     room_rank,
       NULL                     desc_room,
       NULL                     abbreviation,
       NULL                     code_department,
       NULL                     dep_rank,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       ei.dt_first_obs_tstz,
       0                        allocated,
       1                        status_rank,
       ei.flg_status            flg_status_ei,
       NULL                     flg_disch_status,
       NULL,
       epis.id_clinical_service,
       pat.identity_code,
       epis.dt_begin_tstz       dt_admission,
       epis.flg_ehr,
       epis.id_epis_type,
       epis.id_prev_episode
  FROM episode epis
 INNER JOIN epis_info ei
    ON epis.id_episode = ei.id_episode
 INNER JOIN patient pat
    ON epis.id_patient = pat.id_patient
  LEFT OUTER JOIN discharge_schedule ds
    ON ds.id_episode = epis.id_episode
   AND ds.id_patient = pat.id_patient
   AND ds.flg_status = 'Y'
 WHERE epis.id_epis_type = 5
   AND epis.flg_status = 'C'
   AND epis.flg_ehr = 'N'
   AND epis.dt_cancel_tstz IS NOT NULL;
