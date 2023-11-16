CREATE OR REPLACE VIEW V_OUTP_BETW_BASE AS
SELECT
    e.id_episode      id_episode
  ,e.id_visit     id_visit
    ,e.id_epis_type      id_epis_type
    ,e.flg_ehr       flg_ehr
    ,e.dt_begin_tstz     dt_begin_tstz
  ,e.flg_status        flg_status
    ,e.flg_appointment_type  flg_appointment_type
    ,ei.id_dcs_requested   id_dcs_requested
    ,ei.id_room        id_room
    ,ei.id_schedule    id_Schedule
  ,ei.id_software     ei_id_software
  ,ei.id_dep_clin_Serv ei_id_dep_clin_serv
    ,gt.intervention     intervention
  ,gtb.flg_interv      flg_interv
  ,gtb.flg_monitor     flg_monitor
  ,gt.monitorization   monitorization
  ,gtb.flg_nurse_act   flg_nurse_act
  ,gt.nurse_activity   nurse_activity
  ,gt.drug_presc       drug_presc
  ,gtb.flg_drug   flg_drug
    ,e.sys_no                           sys_no
    ,e.sys_yes                          sys_yes
    ,'V'                                k_sched_status_cache
    ,'S'                                sys_selected
    ,'N'                                sys_flg_ehr_n
    ,'S'                                sys_flg_ehr_s
    ,24                                 k_episode_type_interv
    ,e.sys_institution    sys_institution
    ,e.sys_lang           sys_lang
    ,e.sys_software       sys_software
    ,e.sys_prof_id        sys_prof_id
    ,e.sys_epis_status_active    sys_epis_status_active
    ,e.sys_epis_status_inactive  sys_epis_status_inactive
    ,e.sys_lprof                 sys_lprof
    ,ALERT_CONTEXT('G_EPIS_TYPE_NURSE') sys_g_epis_type_nurse
    ,( select pk_sysconfig.get_config('ENABLE_TEAM_FILTER_GRID', e.sys_lprof)   from dual ) sys_use_team_filter
    ,( select pk_sysconfig.get_config('EPIS_TYPE', e.sys_lprof)                 from dual ) sys_epis_type
    ,( select pk_sysconfig.get_config('WL_WAITING_ROOM_AVAILABLE', e.sys_lprof) from dual ) sys_waiting_room_available
    ,( select pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', e.sys_lprof) from dual) sys_waiting_room_sys_external
    ,s.id_dcs_requested          s_id_dcs_requested
  ,s.id_room           s_id_room
  ,s.id_instit_requested     s_id_instit_requested
  ,s.flg_status      s_flg_status
    ,v.id_patient      id_patient
    ,v.id_institution   v_id_institution,
    current_timestamp g_sysdate
  FROM epis_info ei
  JOIN schedule s         ON ei.id_schedule = s.id_schedule
  JOIN (
    select ep.*
    ,'N'                sys_no
    ,'Y'                sys_yes
    ,'V'                k_sched_status_cache
    ,'S'                sys_selected
    ,'N'                sys_flg_ehr_n
    ,'S'                sys_flg_ehr_s
    ,24               k_episode_type_interv
    ,ALERT_CONTEXT( 'i_institution')    sys_institution
    ,ALERT_CONTEXT( 'i_lang')           sys_lang
    ,ALERT_CONTEXT( 'i_software')       sys_software
    ,ALERT_CONTEXT( 'i_prof_id')        sys_prof_id
    ,'A'                                sys_epis_status_active
    ,'I'                                sys_epis_status_inactive
    ,( select profissional( ALERT_CONTEXT( 'i_prof_id'), ALERT_CONTEXT( 'i_institution'), ALERT_CONTEXT( 'i_software')) from dual) sys_lprof
    from (
       select e.*
       from episode e
     where e.flg_ehr IN ( 'N', 'S')
     AND e.flg_status IN ('A', 'I')
     union all
       select e.*
       from episode e
     where e.id_institution = ALERT_CONTEXT( 'i_institution')
     and e.id_epis_type = 24
     AND e.flg_ehr IN ( 'N', 'S')
     AND e.flg_status  = 'A'
       ) ep
    ) e  ON e.id_episode = ei.id_episode
  join visit v      on v.id_visit = e.id_visit
  JOIN grid_task gt         ON gt.id_episode = e.id_episode
  JOIN grid_task_between gtb  ON gtb.id_episode = e.id_episode
  WHERE e.flg_ehr IN ( e.sys_flg_ehr_n, e.sys_flg_ehr_s)
  ;
