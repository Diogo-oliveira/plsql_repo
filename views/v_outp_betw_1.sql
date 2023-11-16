CREATE OR REPLACE VIEW V_OUTP_BETW_1  AS
SELECT
e.id_schedule       id_schedule
,e.id_visit      id_visit
,e.id_episode        id_episode
,sp.id_epis_type       id_epis_type
,e.flg_ehr         flg_ehr
,e.dt_begin_tstz       dt_begin_tstz
,e.flg_status      flg_status
,e.flg_appointment_type    flg_appointment_type
,sg.flg_contact_type     flg_contact_type
,sp.flg_sched        flg_sched
,sp.flg_state        flg_state
,sg.id_patient       id_patient
,e.ei_id_dep_clin_serv     ei_id_dep_clin_serv
,e.drug_presc       gt_drug_presc
,e.flg_interv        flg_interv
,e.flg_drug          flg_drug
,e.intervention       gt_interv_presc
,e.flg_monitor       flg_monitor
,e.monitorization       gt_monit
,e.flg_nurse_act     flg_nurse_act
,e.nurse_activity       gt_nurse_act
,nvl(e.id_room, e.s_id_room)  id_room
,e.id_dcs_requested      id_dcs_requested
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
,e.sys_g_epis_type_nurse         sys_g_epis_type_nurse
,e.sys_use_team_filter           sys_use_team_filter
,e.sys_epis_type                 sys_epis_type
,e.sys_waiting_room_available    sys_waiting_room_available
,e.sys_waiting_room_sys_external sys_waiting_room_sys_external
,e.g_sysdate g_sysdate
--##################
FROM v_outp_betw_base e
join schedule_outp sp on e.id_schedule = sp.id_schedule
JOIN sch_group sg       ON sp.id_schedule = sg.id_schedule
JOIN sch_prof_outp ps     ON sp.id_schedule_outp = ps.id_schedule_outp
JOIN prof_dep_clin_serv pdcs  ON e.ei_id_dep_clin_serv = pdcs.id_dep_clin_serv AND e.s_id_instit_requested = pdcs.id_institution
WHERE sp.id_software = e.sys_software
AND e.s_flg_status != e.k_sched_status_cache -- agendamentos temporários (SCH 3.0)
AND e.s_id_instit_requested = e.sys_institution
AND sp.id_epis_type IN (e.sys_epis_type, e.sys_g_epis_type_nurse)
AND pdcs.id_professional = sys_prof_id
AND pdcs.flg_status = e.sys_selected
AND e.flg_ehr IN ( e.sys_flg_ehr_n, e.sys_flg_ehr_s)
AND e.flg_status IN (e.sys_epis_status_active, e.sys_epis_status_inactive)
AND (
  e.sys_use_team_filter = e.sys_no
  OR
  ps.id_professional IN (
    SELECT /*+ OPT_ESTIMATE(TABLE k ROWS=1) */  k.column_value
    FROM TABLE(pk_grid_amb.get_prof_team_det( e.sys_lprof )) k)
  )
;
