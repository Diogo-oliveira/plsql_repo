create or replace view v_inp_no_bed_02 as
select
  v02.flg_status_discharge
, v02.dt_med_tstz
, v02.dt_pend_tstz
, v02.dt_admin_tstz
, v02.acuity
, v02.id_institution
, v02.sys_lang
, v02.sys_prof_id
, v02.sys_institution
, v02.sys_software
, v02.sys_lprof
, v02.e_id_episode
, v02.dt_begin_tstz
, v02.e_dt_begin_tstz
, v02.dt_end_tstz
, v02.e_dt_cancel_tstz
, v02.dt_first_obs_tstz
, v02.e_id_fast_track
, v02.flg_cancel
, v02.gender
, v02.ei_id_episode
, v02.id_patient
, v02.epis_info_flg_status
, v02.ei_id_first_nurse_resp
, v02.id_visit
, v02.urg_episode
, v02.dt_birth
, v02.dt_deceased
, v02.e_id_department
, v02.v_id_origin
, v02.e_flg_ehr
, v02.e_flg_status
, v02.ei_id_software
, v02.ei_id_professional
, v02.ei_id_room
, v02.id_dep_clin_serv
, v02.color_text
, v02.triage_flg_letter
, v02.id_triage_color
, v02.rank_acuity
, v02.id_first_nurse_resp
, v02.ei_id_schedule
, v02.gt_id_episode
, v02.gt_drug_presc
, v02.gt_icnp_intervention
, v02.gt_nurse_activity
, v02.gt_intervention
, v02.gt_monitorization
, v02.gt_teach_req
, v02.gt_movement
, v02.gt_discharge_pend
, v02.oth_exam_n
, v02.oth_exam_d
, v02.img_exam_n
, v02.img_exam_d
, v02.opinion_state
, v02.pat_gender
, v02.inp_id_epis_type
, v02.id_epis_type
, v02.sys_yes
, v02.sys_no
from v_inp_no_bed v02
where v02.e_flg_status = alert_context('g_epis_status_inactive')
AND v02.dt_end_tstz > cast( (current_timestamp - numtodsinterval( alert_context('l_edis_timelimit'), 'HOUR') ) as timestamp with local time zone );
