create or replace view v_grid_outp_room_dsc as
select
v00.view_id view_id
,pk_grid.get_schedule_real_state(v00.sp_flg_state, v00.e_flg_ehr) get_schedule_real_state
,v00.CMPT_CODE_COMPLAINT
,v00.sys_no flg_group_header
,v00.E_ID_DEPARTMENT
,v00.E_ID_VISIT
,v00.E_FLG_EHR
,v00.e_flg_status
,v00.E_DT_BEGIN_TSTZ
,v00.EC_ID_COMPLAINT
,v00.EC_PATIENT_COMPLAINT
,v00.EI_ID_EPISODE
,v00.EI_ID_SOFTWARE
,v00.EI_ID_PROFESSIONAL
,v00.EI_ID_FIRST_NURSE_RESP
,v00.EI_ID_ROOM
,v00.EI_ID_DEP_CLIN_SERV
,v00.EI_NICK_NAME
,v00.EI_NAME
,nvl( v00.ei_name, v00.ei_nick_name ) prof_ei_name
,v00.GT_ID_EPISODE
,v00.GT_DRUG_PRESC
,v00.GT_ICNP_INTERVENTION
,v00.GT_NURSE_ACTIVITY
,v00.GT_INTERVENTION
,v00.GT_MONITORIZATION
,v00.GT_TEACH_REQ
,v00.PAT_GENDER
,v00.PS_NICK_NAME
,v00.PS_NAME
,nvl( v00.ps_name, v00.ps_nick_name ) PROF_PS_NAME
,v00.PS_ID_PROFESSIONAL
,v00.S_ID_SCHEDULE
,v00.S_ID_GROUP
,v00.S_FLG_PRESENT
,v00.S_ID_DCS_REQUESTED
,v00.S_ID_SCH_EVENT
,v00.SE_CODE_SCH_EVENT
,v00.SG_FLG_CONTACT_TYPE
,v00.SP_DT_TARGET_TSTZ
,v00.SP_ID_EPIS_TYPE
,v00.SP_FLG_STATE
,v00.SP_FLG_SCHED
,v00.SP_ID_SOFTWARE
,v00.S_FLG_STATUS
,v00.SE_ID_SCH_EVENT
,v00.SG_ID_PATIENT
,v00.SYS_INSTITUTION
,v00.SYS_LANG
,v00.SYS_SOFTWARE
,v00.SYS_PROF_ID
,v00.SYS_DT_MIN
,v00.SYS_DT_MAX
,v00.SYS_SCHED_ADM_DISCH
,v00.sys_epis_type_nurse
,v00.SYS_LPROF
,v00.sys_no
,v00.sys_yes
,v00.s_id_instit_requested
, d.flg_Status disch_flg_status
,v00.e_id_epis_type
from v_grid_outp_base v00
join prof_room pr on pr.id_room = v00.ei_id_room and pr.id_professional = v00.sys_prof_id
join discharge d on d.id_episode = v00.EI_ID_EPISODE;
