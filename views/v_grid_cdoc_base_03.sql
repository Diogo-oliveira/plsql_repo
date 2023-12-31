CREATE OR REPLACE VIEW V_GRID_CDOC_BASE_03 AS
SELECT
v01.flg_status_discharge,
v01.e_id_department,
v01.e_id_visit,
v01.v_id_origin,
v01.id_institution,
v01.id_visit,
v01.e_flg_ehr,
v01.e_dt_begin_tstz,
v01.e_flg_status,
v01.e_id_episode,
v01.e_id_fast_track,
v01.dt_begin_tstz,
v01.dt_end_tstz,
v01.e_dt_cancel_tstz,
v01.ei_id_episode,
v01.ei_id_software,
v01.ei_id_professional,
v01.ei_id_first_nurse_resp,
v01.ei_id_room,
v01.ei_id_dep_clin_serv,
v01.acuity,
v01.color_text,
v01.triage_flg_letter,
v01.id_triage_color,
v01.rank_acuity,
v01.id_first_nurse_resp,
v01.dt_first_obs_tstz,
v01.epis_info_flg_status,
v01.ei_id_schedule,
v01.gt_id_episode,
v01.gt_drug_presc,
v01.gt_icnp_intervention,
v01.gt_nurse_activity,
v01.gt_intervention,
v01.gt_monitorization,
v01.gt_teach_req,
v01.gt_movement,
v01.gt_discharge_pend,
v01.oth_exam_n,
v01.oth_exam_d,
v01.img_exam_n,
v01.img_exam_d,
v01.opinion_state,
v01.pat_gender,
v01.id_patient,
v01.ei_nick_name,
v01.ei_name,
v01.id_epis_type,
v01.sys_institution,
v01.sys_lang,
v01.sys_software,
v01.sys_prof_id,
v01.sys_lprof,
v01.sys_yes,
v01.sys_no,
v01.dt_med_tstz,
v01.dt_pend_tstz,
v01.dt_admin_tstz
FROM V_GRID_CDOC_BASE_01 v01
union all
SELECT
vb02.flg_status_discharge,
vb02.e_id_department,
vb02.e_id_visit,
vb02.v_id_origin,
vb02.id_institution,
vb02.id_visit,
vb02.e_flg_ehr,
vb02.e_dt_begin_tstz,
vb02.e_flg_status,
vb02.e_id_episode,
vb02.e_id_fast_track,
vb02.dt_begin_tstz,
vb02.dt_end_tstz,
vb02.e_dt_cancel_tstz,
vb02.ei_id_episode,
vb02.ei_id_software,
vb02.ei_id_professional,
vb02.ei_id_first_nurse_resp,
vb02.ei_id_room,
vb02.ei_id_dep_clin_serv,
vb02.acuity,
vb02.color_text,
vb02.triage_flg_letter,
vb02.id_triage_color,
vb02.rank_acuity,
vb02.id_first_nurse_resp,
vb02.dt_first_obs_tstz,
vb02.epis_info_flg_status,
vb02.ei_id_schedule,
vb02.gt_id_episode,
vb02.gt_drug_presc,
vb02.gt_icnp_intervention,
vb02.gt_nurse_activity,
vb02.gt_intervention,
vb02.gt_monitorization,
vb02.gt_teach_req,
vb02.gt_movement,
vb02.gt_discharge_pend,
vb02.oth_exam_n,
vb02.oth_exam_d,
vb02.img_exam_n,
vb02.img_exam_d,
vb02.opinion_state,
vb02.pat_gender,
vb02.id_patient,
vb02.ei_nick_name,
vb02.ei_name,
vb02.id_epis_type,
vb02.sys_institution,
vb02.sys_lang,
vb02.sys_software,
vb02.sys_prof_id,
vb02.sys_lprof,
vb02.sys_yes,
vb02.sys_no,
vb02.dt_med_tstz,
vb02.dt_pend_tstz,
vb02.dt_admin_tstz
FROM V_GRID_CDOC_BASE_02 vb02;
