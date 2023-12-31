create or replace view v_inp_no_bed_01 as
select
  v01.flg_status_discharge
, v01.dt_med_tstz
, v01.dt_pend_tstz
, v01.dt_admin_tstz
, v01.acuity
, v01.id_institution
, v01.sys_lang
, v01.sys_prof_id
, v01.sys_institution
, v01.sys_software
, v01.sys_lprof
, v01.e_id_episode
, v01.dt_begin_tstz
, v01.e_dt_begin_tstz
, v01.dt_end_tstz
, v01.e_dt_cancel_tstz
, v01.dt_first_obs_tstz
, v01.e_id_fast_track
, v01.flg_cancel
, v01.gender
, v01.ei_id_episode
, v01.id_patient
, v01.epis_info_flg_status
, v01.ei_id_first_nurse_resp
, v01.id_visit
, v01.urg_episode
, v01.dt_birth
, v01.dt_deceased
, v01.e_id_department
, v01.v_id_origin
, v01.e_flg_ehr
, v01.e_flg_status
, v01.ei_id_software
, v01.ei_id_professional
, v01.ei_id_room
, v01.id_dep_clin_serv
, v01.color_text
, v01.triage_flg_letter
, v01.id_triage_color
, v01.rank_acuity
, v01.id_first_nurse_resp
, v01.ei_id_schedule
, v01.gt_id_episode
, v01.gt_drug_presc
, v01.gt_icnp_intervention
, v01.gt_nurse_activity
, v01.gt_intervention
, v01.gt_monitorization
, v01.gt_teach_req
, v01.gt_movement
, v01.gt_discharge_pend
, v01.oth_exam_n
, v01.oth_exam_d
, v01.img_exam_n
, v01.img_exam_d
, v01.opinion_state
, v01.pat_gender
, v01.inp_id_epis_type
, v01.id_epis_type
, v01.sys_yes
, v01.sys_no
from v_inp_no_bed v01
where v01.e_flg_status in ( alert_context('e_flg_status_a'), alert_context('e_flg_status_p' )  );
