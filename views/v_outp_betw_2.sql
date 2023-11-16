CREATE OR REPLACE VIEW V_OUTP_BETW_2  AS
SELECT
e.id_schedule         id_Schedule
,e.id_patient         id_patient
,e.id_episode         id_episode
,e.id_visit       id_visit
,e.flg_status    flg_Status
,e.id_epis_type       id_epis_type
,''               flg_state
,''               flg_sched
,e.id_dcs_requested     id_dcs_requested
,e.flg_ehr            flg_ehr
,e.dt_begin_tstz        dt_begin_tstz
,e.flg_appointment_type   flg_appointment_type
,e.id_room            id_room
,''               flg_contact_type
,''           flg_drug
,''               drug_presc
,''               gt_drug_presc
,e.flg_interv         flg_interv
,sp.flg_state        sp_flg_state
,e.intervention       gt_interv_presc
,''             flg_monitor
,''           flg_nurse_act
,''               monit
,''               gt_monit
,''               nurse_act
,''               gt_nurse_act
,e.s_id_dcs_requested           s_id_dcs_requested
,e.sys_no          sys_no
,e.sys_yes                   sys_yes
,e.k_sched_status_cache      k_sched_status_cache
,e.sys_selected              sys_selected
,e.sys_flg_ehr_n             sys_flg_ehr_n
,e.sys_flg_ehr_s             sys_flg_ehr_s
,e.k_episode_type_interv     k_episode_type_interv
,e.sys_institution           sys_institution
,e.sys_lang                  sys_lang
,e.sys_software              sys_software
,e.sys_prof_id               sys_prof_id
,e.sys_lprof               sys_lprof
,e.sys_epis_status_active    sys_epis_status_active
,e.sys_epis_status_inactive  sys_epis_status_inactive
,e.sys_g_epis_type_nurse      sys_g_epis_type_nurse
,e.sys_use_team_filter              sys_use_team_filter
,e.sys_epis_type                    sys_epis_type
,e.sys_waiting_room_available       sys_waiting_room_available
,e.sys_waiting_room_sys_external    sys_waiting_room_sys_external
,e.g_sysdate                        g_sysdate
FROM v_outp_betw_base e
LEFT JOIN schedule_outp sp  ON sp.id_schedule = e.id_schedule
WHERE e.id_epis_type = e.k_episode_type_interv
AND e.flg_ehr IN ( e.sys_flg_ehr_n, e.sys_flg_ehr_s)
AND e.flg_status = e.sys_epis_status_active
AND e.v_id_institution = e.sys_institution
AND e.ei_id_software = e.sys_software;
