CREATE OR REPLACE VIEW V_PAT_PHARM_ACTIVE AS
SELECT t.id_episode,
       t.id_visit,
       t.id_patient,
       t.flg_status_e,
       t.flg_ehr,
       t.id_epis_type,
       'EPIS_TYPE.CODE_EPIS_TYPE.' || t.id_epis_type code_epis_type,
       t.id_software,
       t.id_first_nurse_resp,
       t.id_professional,
       t.id_institution,
       t.dt_begin_tstz,
       t.dt_cancel_tstz,
       t.id_bed,
       t.desc_bed,
       t.code_bed,
       t.bed_rank,
       t.desc_room_abbreviation,
       t.code_abbreviation,
       t.code_room,
       t.desc_room,
       t.abbreviation,
       t.code_department,
       t.id_department,
       t.dep_rank,
       t.gender,
       t.dt_birth,
       t.dt_deceased,
       t.age,
       t.dt_first_obs_tstz,
       nvl2(t.id_bed, 1, 0) allocated,
       0 status_rank,
       t.flg_status_ei,
       t.drug_presc,
       t.drug_req
  FROM (SELECT epis.id_episode,
               epis.id_visit,
               epis.id_patient,
               epis.flg_status           flg_status_e,
               epis.flg_ehr,
               epis.id_epis_type,
               ei.id_software,
               ei.id_first_nurse_resp,
               ei.id_professional,
               epis.id_institution,
               epis.dt_begin_tstz,
               epis.dt_cancel_tstz,
               bd.id_bed,
               bd.desc_bed,
               bd.code_bed,
               bd.rank                   bed_rank,
               ro.desc_room_abbreviation,
               ro.code_abbreviation,
               ro.code_room,
               ro.desc_room,
               dpt.abbreviation,
               dpt.code_department,
               dpt.id_department,
               dpt.rank                  dep_rank,
               pat.gender,
               pat.dt_birth,
               pat.dt_deceased,
               pat.age,
               ei.dt_first_obs_tstz,
               ei.flg_status             flg_status_ei,
               gt.drug_presc,
               gt.drug_req
          FROM episode epis
          JOIN patient pat
            ON epis.id_patient = pat.id_patient
          JOIN epis_info ei
            ON epis.id_episode = ei.id_episode
          LEFT JOIN bed bd
            ON ei.id_bed = bd.id_bed
          LEFT JOIN room ro
            ON bd.id_room = ro.id_room
          LEFT JOIN department dpt
            ON ro.id_department = dpt.id_department
          LEFT JOIN grid_task gt
            ON (gt.id_episode = epis.id_episode)
          JOIN tbl_temp tt
            ON (tt.num_1 = epis.id_episode
           AND tt.vc_1 = 'PHA_WHERE')
         WHERE epis.flg_status IN ('A', 'P')
           AND epis.flg_ehr = 'N'
           AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')) t;
