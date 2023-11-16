create or replace view V_GRID_HHC_BASE as
select
VIEW_TYPE view_id
,( select pk_grid.get_schedule_real_state(v00.sp_flg_state, v00.e_flg_ehr) from dual ) get_schedule_real_state
,flg_group_header
,E_ID_DEPARTMENT
,E_ID_VISIT
,E_FLG_EHR
,e_flg_status
,E_DT_BEGIN_TSTZ
,EI_ID_EPISODE
,EI_ID_SOFTWARE
,EI_ID_PROFESSIONAL
,EI_ID_FIRST_NURSE_RESP
,EI_ID_ROOM
,EI_ID_DEP_CLIN_SERV
,EI_NICK_NAME
,EI_NAME
,nvl( ei_name, ei_nick_name ) prof_ei_name
,GT_ID_EPISODE
,GT_DRUG_PRESC
,GT_ICNP_INTERVENTION
,GT_NURSE_ACTIVITY
,GT_INTERVENTION
,GT_MONITORIZATION
,GT_TEACH_REQ
,PAT_GENDER
,PS_NICK_NAME
,PS_NAME
,nvl( ps_name, ps_nick_name ) PROF_PS_NAME
,PS_ID_PROFESSIONAL
,S_ID_SCHEDULE
,S_ID_GROUP
,S_FLG_PRESENT
,S_ID_DCS_REQUESTED
,S_ID_SCH_EVENT
,SE_CODE_SCH_EVENT
,SG_FLG_CONTACT_TYPE
,SP_DT_TARGET_TSTZ
,SP_ID_EPIS_TYPE
,SP_FLG_STATE
,SP_FLG_SCHED
,SP_ID_SOFTWARE
,S_FLG_STATUS
,SE_ID_SCH_EVENT
,SG_ID_PATIENT
,SYS_INSTITUTION
,SYS_LANG
,SYS_SOFTWARE
,SYS_PROF_ID
,SYS_DT_MIN
,SYS_DT_MAX
,SYS_SCHED_ADM_DISCH
, s_id_instit_requested
, SYS_LPROF
, sys_no
, sys_yes
, flg_leader
, e_id_epis_type
from
  (
    select
    VIEW_TYPE
    ,flg_group_header
    ,E_ID_DEPARTMENT
    ,E_ID_VISIT
    ,E_FLG_EHR
    ,e_flg_status
    ,E_DT_BEGIN_TSTZ
    ,EI_ID_EPISODE
    ,EI_ID_SOFTWARE
    ,EI_ID_PROFESSIONAL
    ,EI_ID_FIRST_NURSE_RESP
    ,EI_ID_ROOM
    ,EI_ID_DEP_CLIN_SERV
    ,EI_NICK_NAME
    ,EI_NAME
    ,GT_ID_EPISODE
    ,GT_DRUG_PRESC
    ,GT_ICNP_INTERVENTION
    ,GT_NURSE_ACTIVITY
    ,GT_INTERVENTION
    ,GT_MONITORIZATION
    ,GT_TEACH_REQ
    ,PAT_GENDER
    ,PS_NICK_NAME
    ,PS_NAME
    ,PS_ID_PROFESSIONAL
    ,S_ID_SCHEDULE
    ,S_ID_GROUP
    ,S_FLG_PRESENT
    ,S_ID_DCS_REQUESTED
    ,S_ID_SCH_EVENT
    ,SE_CODE_SCH_EVENT
    ,SG_FLG_CONTACT_TYPE
    ,SP_DT_TARGET_TSTZ
    ,SP_ID_EPIS_TYPE
    ,SP_FLG_STATE
    ,SP_FLG_SCHED
    ,SP_ID_SOFTWARE
    ,S_FLG_STATUS
    ,SE_ID_SCH_EVENT
    ,SG_ID_PATIENT
    ,SYS_INSTITUTION
    ,SYS_LANG
    ,SYS_SOFTWARE
    ,SYS_PROF_ID
    , (select pk_date_utils.get_string_tstz(i_lang => sys_lang, i_prof => sys_lprof, i_timestamp => alert_context('l_dt_min'), i_timezone  => '') from dual )SYS_DT_MIN
    ,( select pk_date_utils.add_to_ltstz(i_timestamp =>
        pk_date_utils.add_days(
              i_lang   => sys_lang,
              i_prof   => sys_lprof,
              i_date   => pk_date_utils.get_string_tstz(
                      i_lang      => sys_lang,
                      i_prof      => sys_lprof,
                      i_timestamp => alert_context('l_dt_min'),
                      i_timezone  => ''),
              i_amount => alert_context('AMOUNT')),
        i_amount    => -1,
        i_unit      => 'SECOND') from dual ) SYS_DT_MAX

    ,SYS_SCHED_ADM_DISCH
    , s_id_instit_requested
    , SYS_LPROF
    , sys_no
    , sys_yes
    , flg_leader
    , e_id_epis_type
    from V_GRID_HHC_BASE_00 v0
    WHERE v0.s_flg_status NOT IN ('V')
     and v0.s_id_instit_requested = v0.SYS_INSTITUTION) v00
  where v00.sp_dt_target_tstz between cast( v00.sys_dt_min as timestamp with local time zone )
  and cast( v00.sys_dt_max as timestamp with local time zone )
;
