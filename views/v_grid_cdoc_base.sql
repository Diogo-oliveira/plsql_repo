CREATE OR REPLACE VIEW V_GRID_CDOC_BASE AS
SELECT e.id_department e_id_department,
       e.id_visit e_id_visit,
       v.id_origin v_id_origin,
       v.id_institution id_institution,
       v.id_visit id_visit,
       d.flg_status flg_status_discharge,
       e.flg_ehr e_flg_ehr,
       e.dt_begin_tstz e_dt_begin_tstz,
       e.flg_status e_flg_status,
       e.id_episode e_id_episode,
       e.id_fast_track e_id_fast_track,
       e.dt_begin_tstz dt_begin_tstz,
       e.dt_end_tstz dt_end_tstz,
       e.dt_cancel_tstz e_dt_cancel_tstz,
       ei.id_episode ei_id_episode,
       ei.id_software ei_id_software,
       ei.id_professional ei_id_professional,
       ei.id_first_nurse_resp ei_id_first_nurse_resp,
       ei.id_room ei_id_room,
       ei.id_dep_clin_serv ei_id_dep_clin_serv,
       ei.triage_acuity acuity,
       ei.triage_color_text color_text,
       ei.triage_flg_letter triage_flg_letter,
       ei.id_triage_color id_triage_color,
       ei.triage_rank_acuity rank_acuity,
       ei.id_first_nurse_resp id_first_nurse_resp,
       ei.dt_first_obs_tstz dt_first_obs_tstz,
       ei.flg_status epis_info_flg_status,
       ei.id_schedule ei_id_schedule,
       gt.id_episode gt_id_episode,
       gt.drug_presc gt_drug_presc,
       gt.icnp_intervention gt_icnp_intervention,
       gt.nurse_activity gt_nurse_activity,
       gt.intervention gt_intervention,
       gt.monitorization gt_monitorization,
       gt.teach_req gt_teach_req,
       gt.movement gt_movement,
       gt.discharge_pend gt_discharge_pend,
       gt.oth_exam_n oth_exam_n,
       gt.oth_exam_d oth_exam_d,
       gt.img_exam_n img_exam_n,
       gt.img_exam_d img_exam_d,
       gt.opinion_state opinion_state,
       pat.gender pat_gender,
       pat.id_patient id_patient,
       prof_ei.nick_name ei_nick_name,
       prof_ei.name ei_name,
       e.id_epis_type id_epis_type,
       alert_context('i_institution') sys_institution,
       alert_context('i_lang') sys_lang,
       alert_context('i_software') sys_software,
       alert_context('i_prof_id') sys_prof_id,
       profissional(alert_context('i_prof_id'), alert_context('i_institution'), alert_context('i_software')) sys_lprof,
       'Y' sys_yes,
       'N' sys_no,
       d.dt_med_tstz,
       d.dt_pend_tstz,
       d.dt_admin_tstz
  FROM episode e
  JOIN visit v
    ON v.id_visit = e.id_visit
  JOIN patient pat
    ON v.id_patient = pat.id_patient
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN professional prof_ei
    ON prof_ei.id_professional = ei.id_professional
  LEFT JOIN grid_task gt
    ON gt.id_episode = ei.id_episode
  LEFT JOIN discharge d
    ON d.id_episode = e.id_episode
   AND d.flg_status != 'C'
 WHERE e.flg_ehr = alert_context('e_flg_ehr')
   AND v.id_institution = alert_context('i_institution')
   --AND d.dt_admin_tstz IS NULL
   AND e.id_epis_type = alert_context('id_epis_type')
   AND e.id_institution = alert_context('i_institution');
