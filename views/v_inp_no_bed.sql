create or replace view v_inp_no_bed as
select
  t.Flg_Status_Discharge
, t.dt_med_tstz
,t.dt_pend_tstz
,t.dt_admin_tstz
, t.triage_acuity acuity--
, t.id_institution id_institution
, t.sys_lang
, t.sys_prof_id
, t.sys_institution
, t.sys_software
, t.sys_lprof
, t.id_episode e_id_episode
, t.dt_begin_tstz dt_begin_tstz
, t.dt_begin_tstz e_dt_begin_tstz
, t.dt_end_tstz
, t.e_dt_cancel_tstz
, t.dt_first_obs_tstz
, t.id_fast_track e_id_fast_track
, 'N' flg_cancel
, t.gender
, t.ei_id_episode ei_id_episode
, t.id_patient id_patient
, t.flg_status_ei epis_info_flg_status
, t.id_first_nurse_resp ei_id_first_nurse_resp
, t.id_visit id_visit--
, t.urg_episode
, t.dt_birth
, t.dt_deceased
, t.id_department e_id_department--
, t.id_origin v_id_origin--
, t.flg_ehr e_flg_ehr
, t.flg_status e_flg_status
, t.id_software ei_id_software
, t.id_professional ei_id_professional
, t.ei_id_room
, t.id_dep_clin_serv
, t.color_text
, t.triage_flg_letter
, t.id_triage_color
, t.triage_rank_acuity rank_acuity
, t.id_first_nurse_resp
, t.id_schedule ei_id_schedule
, t.gt_id_episode
, t.gt_drug_presc
, t.gt_icnp_intervention
, t.gt_nurse_activity
, t.gt_intervention
, t.gt_monitorization
, t.gt_teach_req
, t.gt_movement
, t.gt_discharge_pend
, t.oth_exam_n
, t.oth_exam_d
, t.img_exam_n
, t.img_exam_d
, t.opinion_state
, t.gender pat_gender
, t.inp_id_epis_type
, t.id_epis_type
, 'Y' sys_yes
, 'N' sys_no
from
  ( select
  vinp.*
  ,sys_context('ALERT_CONTEXT', 'i_institution') sys_institution
  ,sys_context('ALERT_CONTEXT', 'i_lang') sys_lang
  ,sys_context('ALERT_CONTEXT', 'i_software') sys_software
  ,sys_context('ALERT_CONTEXT', 'i_prof_id') sys_prof_id
  ,profissional(alert_context('i_prof_id'), alert_context('i_institution'), alert_context('i_software')) sys_lprof
  from v_inp_no_bed_alloc vinp where rownum > 0
  )  t
;
