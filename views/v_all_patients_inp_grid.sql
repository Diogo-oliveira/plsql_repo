CREATE OR REPLACE VIEW V_ALL_PATIENTS_INP_GRID AS
SELECT epis.id_episode,
       epis.id_visit,
       epis.id_patient, 
       epis.flg_status flg_status_e,
       epis.flg_ehr,
       epis.id_epis_type,
       ei.id_first_nurse_resp,
       ei.id_professional,
       epis.id_institution,
       epis.dt_begin_tstz,
       epis.dt_cancel_tstz,
       bd.id_bed,
       bd.desc_bed,
       bd.code_bed,
       bd.rank bed_rank,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.rank room_rank,
       ro.desc_room,
       ro.id_room,
       dpt.abbreviation,
       dpt.code_department,
       dcs.id_department,
       dpt.rank dep_rank,
       dcs.id_dep_clin_serv,
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
       epis.id_clinical_service,
       pat.identity_code,
       epis.dt_begin_tstz dt_admission,
     epis.id_prev_episode,
     dch.dt_pend_tstz
  FROM episode epis
 INNER JOIN patient pat
    ON epis.id_patient = pat.id_patient
 INNER JOIN epis_info ei
    ON epis.id_episode = ei.id_episode
 INNER JOIN dep_clin_serv dcs
    ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
  LEFT OUTER JOIN discharge dch
    ON (dch.id_episode = epis.id_episode AND dch.flg_status IN ('A', 'P') and dch.dt_admin_tstz is null)
  LEFT OUTER JOIN bed bd
    ON ei.id_bed = bd.id_bed
  LEFT OUTER JOIN room ro
    ON bd.id_room = ro.id_room
  LEFT OUTER JOIN department dpt
    ON ro.id_department = dpt.id_department;
