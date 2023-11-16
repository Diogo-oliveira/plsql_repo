CREATE OR REPLACE VIEW V_INP_NO_BED_ALLOC AS
SELECT flg_Status_discharge,
  dt_med_tstz,
  dt_pend_tstz,
  dt_admin_tstz,
       id_episode,
       id_institution,
       color_text,
       id_visit,
       flg_type,
       inp_or_not,
       dt_begin_tstz,
       dt_end_tstz,
			 dt_cancel_tstz e_dt_cancel_tstz,
       id_patient,
       id_origin,
       dt_birth,
       dt_deceased,
       age,
       gender,
       id_first_nurse_resp,
       flg_status_ei,
       dt_first_obs_tstz,
       id_bed,
       code_bed,
       id_room,
       id_fast_track,
       code_room,
       desc_room_abbreviation,
       code_abbreviation,
       id_professional,
       desc_room,
       urg_episode,
       id_software,
       id_department,
       img_exam_n,
       img_exam_d,
       oth_exam_n,
       oth_exam_d,
       flg_ehr,
       flg_status,
       ei_id_episode,
       id_dep_clin_serv,
       triage_acuity,
       triage_flg_letter,
       id_triage_color,
       triage_rank_acuity,
       id_schedule,
       gt_id_episode,
       gt_drug_presc,
       gt_icnp_intervention,
       gt_nurse_activity,
       gt_intervention,
       gt_monitorization,
       gt_teach_req,
       gt_movement,
       gt_discharge_pend,
       opinion_state,
       id_epis_type inp_id_epis_type,
       id_epis_type,
       ei_id_room
  FROM (SELECT d.flg_status flg_Status_discharge,
  d.dt_med_tstz,
  d.dt_pend_tstz,
  d.dt_admin_tstz,
               inp.dt_cancel_tstz,
               ei.triage_color_text color_text,
               ei.id_episode ei_id_episode,
               ei.id_room ei_id_room,
               ei.id_dep_clin_serv,
               ei.triage_acuity,
               ei.triage_flg_letter,
               ei.id_triage_color,
               ei.triage_rank_acuity,
               ei.id_schedule,
               urg.dt_end_tstz,
               inp.id_epis_type inp_id_epis_type,
               inp.id_episode,
               inp.id_visit,
               inp.flg_ehr,
               inp.flg_status,
               v.id_institution,
               idp.flg_type,
               ei.id_professional,
               instr(nvl(idp.flg_type, 'X'), 'I') inp_or_not,
               inp.dt_begin_tstz,
               v.id_patient,
               v.id_origin,
               pat.dt_birth,
               pat.dt_deceased,
               pat.age,
               pat.gender,
               ei.id_first_nurse_resp,
               gea.epis_info_flg_status flg_status_ei,
               gea.dt_first_obs_tstz dt_first_obs_tstz,
               bd.id_bed,
               bd.code_bed,
               r.id_room,
               urg.id_fast_track,
               r.code_room,
               r.desc_room_abbreviation,
               r.code_abbreviation,
               r.desc_room,
               inp.id_department,
               ei.id_software,
               urg.id_episode urg_episode,
               gt.img_exam_n,
               gt.img_exam_d,
               gt.oth_exam_n,
               gt.oth_exam_d,
               gt.id_episode gt_id_episode,
               gt.drug_presc gt_drug_presc,
               gt.icnp_intervention gt_icnp_intervention,
               gt.nurse_activity gt_nurse_activity,
               gt.intervention gt_intervention,
               gt.monitorization gt_monitorization,
               gt.teach_req gt_teach_req,
               gt.movement gt_movement,
               gt.discharge_pend gt_discharge_pend,
               gt.opinion_state opinion_state,
               urg.id_epis_type id_epis_type
          FROM episode inp
          JOIN visit v
            ON inp.id_visit = v.id_visit
          JOIN patient pat
            ON pat.id_patient = v.id_patient
          JOIN epis_info ei
            ON ei.id_episode = inp.id_episode
          JOIN episode urg
            ON urg.id_episode = inp.id_prev_episode
          JOIN discharge d
            ON d.id_episode = urg.id_episode
          JOIN grids_ea gea
            ON gea.id_episode = inp.id_episode
          LEFT JOIN room r
            ON r.id_room = ei.id_room
          LEFT JOIN bed bd
            ON bd.id_bed = ei.id_bed
          LEFT JOIN room iro
            ON iro.id_room = bd.id_room
          LEFT JOIN department idp
            ON idp.id_department = iro.id_department
          LEFT JOIN grid_task gt
            ON gt.id_episode = inp.id_episode
         WHERE urg.id_epis_type = 2
           AND v.id_institution =to_number(sys_context('ALERT_CONTEXT', 'i_institution'))
           AND inp.id_epis_type = 5
           AND d.flg_status IN ('A', 'P')
           AND rownum > 0) xv
where  INP_OR_NOT = 0;
