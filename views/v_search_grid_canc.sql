CREATE OR REPLACE VIEW V_SEARCH_GRID_CANC AS
SELECT DISTINCT epis.id_episode,
                epis.id_visit,
                epis.id_patient,
                epis.flg_status flg_status_e,
                epis.flg_ehr,
                epis.id_epis_type,
                'EPIS_TYPE.CODE_EPIS_TYPE.' || epis.id_epis_type code_epis_type,
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
                0 status_rank,
                ei.flg_status flg_status_ei,
                epis.id_clinical_service,
                pat.identity_code,
                epis.dt_begin_tstz dt_admission,
                epis.id_prev_episode,
                s.dt_begin_tstz dt_schedule_tstz,
                s.id_schedule
  FROM episode epis
  JOIN epis_info ei
    ON ei.id_episode = epis.id_episode 
  JOIN schedule s
    ON s.id_schedule = ei.id_schedule
  JOIN patient pat
    ON pat.id_patient = epis.id_patient
  JOIN dep_clin_serv dcs
    ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
  LEFT OUTER JOIN bed bd
    ON ei.id_bed = bd.id_bed
  LEFT OUTER JOIN room ro
    ON bd.id_room = ro.id_room
  LEFT OUTER JOIN department dpt
    ON ro.id_department = dpt.id_department
  JOIN tbl_temp tt
    ON (tt.num_1 = epis.id_episode AND tt.vc_1 = 'CANC_WHERE')
 WHERE epis.flg_status IN ('C')
   AND epis.flg_ehr != 'E'
   AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution');
