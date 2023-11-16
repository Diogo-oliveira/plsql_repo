CREATE OR REPLACE VIEW ALERT.V_PHA_DISPENSED_PAT AS
SELECT t.id_episode,
       t.id_institution,
       t.id_software,
       t.id_patient,
       t.dt_birth,
       t.dt_deceased,
       t.gender,
       t.age,
       t.id_bed,
       t.desc_bed,
       t.code_bed,
       t.bed_rank,
       t.desc_room_abbreviation,
       t.code_abbreviation,
       t.code_room,
       t.room_rank,
       t.desc_room,
       t.abbreviation,
       t.code_department,
       t.id_department,
       t.dep_rank,
       t.id_dep_clin_serv,
       t.dt_first_obs_tstz,
       t.allocated,
       t.flg_status_ei,
       t.code_epis_type,
       t.drug_presc,
       t.drug_req,
       t.disp_ivroom,
       t.disp_task
  FROM (SELECT e.id_episode,
               e.id_institution,
               ei.id_software,
               pat.id_patient,
               pat.dt_birth,
               pat.dt_deceased,
               pat.gender,
               pat.age,
               b.id_bed,
               b.desc_bed,
               b.code_bed,
               b.rank bed_rank,
               r.desc_room_abbreviation,
               r.code_abbreviation,
               r.code_room,
               r.rank room_rank,
               r.desc_room,
               dpt.abbreviation,
               dpt.code_department,
               decode(e.id_department_requested,
                      -1,
                      nvl(r.id_department, dcs.id_department),
                      decode(b.id_bed, NULL, e.id_department_requested, nvl(r.id_department, dcs.id_department))) id_department,
               dpt.rank dep_rank,
               dcs.id_dep_clin_serv,
               ei.dt_first_obs_tstz,
               nvl2(b.id_bed, 1, 0) allocated,
               ei.flg_status flg_status_ei,
               'EPIS_TYPE.CODE_EPIS_TYPE.' || e.id_epis_type code_epis_type,
               gt.drug_presc,
               gt.drug_req,
               gt.disp_ivroom,
               gt.disp_task
          FROM v_disp vd
          JOIN grids_ea gea
            ON gea.id_episode = vd.id_epis_create
           AND gea.episode_flg_status IN ('A', 'P')
          JOIN epis_info ei
            ON ei.id_episode = gea.id_episode
          JOIN episode e
            ON e.id_episode = gea.id_episode
          JOIN patient pat
            ON pat.id_patient = gea.id_patient
            AND pat.flg_status = 'A'
          JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = gea.id_dep_clin_serv
           AND dcs.flg_available = 'Y'
          LEFT JOIN bed b
            ON b.id_bed = gea.id_bed
          LEFT JOIN room r
            ON r.id_room = b.id_room
          LEFT JOIN department dpt
            ON r.id_department = dpt.id_department
          LEFT JOIN grid_task gt
            ON gt.id_episode = gea.id_episode
          JOIN v_pha_car_model pcm
            ON pcm.id_pha_car_model = vd.id_pha_car_model
          JOIN tbl_temp tt
            ON tt.num_1 = pcm.id_pha_car_model
         WHERE gea.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND vd.id_status_dispense IN (518, 522)) t
 GROUP BY t.id_episode,
          t.id_institution,
          t.id_software,
          t.id_patient,
          t.dt_birth,
          t.dt_deceased,
          t.gender,
          t.age,
          t.id_bed,
          t.desc_bed,
          t.code_bed,
          t.bed_rank,
          t.desc_room_abbreviation,
          t.code_abbreviation,
          t.code_room,
          t.room_rank,
          t.desc_room,
          t.abbreviation,
          t.code_department,
          t.id_department,
          t.dep_rank,
          t.id_dep_clin_serv,
          t.dt_first_obs_tstz,
          t.allocated,
          t.flg_status_ei,
          t.code_epis_type,
          t.drug_presc,
          t.drug_req,
          t.disp_ivroom,
          t.disp_task;
