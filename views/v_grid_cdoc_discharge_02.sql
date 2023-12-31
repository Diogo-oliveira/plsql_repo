CREATE OR REPLACE VIEW V_GRID_CDOC_DISCHARGE_02 AS
SELECT
 v02.E_ID_DEPARTMENT
,v02.E_ID_VISIT
,v02.V_ID_ORIGIN
,v02.ID_INSTITUTION
,v02.ID_VISIT
,v02.E_FLG_EHR
,v02.E_DT_BEGIN_TSTZ
,v02.dt_end_tstz
,v02.E_FLG_STATUS
,v02.E_ID_EPISODE
,v02.E_ID_FAST_TRACK
,v02.dt_begin_tstz
,v02.e_dt_cancel_tstz
,v02.EI_ID_EPISODE
,v02.EI_ID_SOFTWARE
,v02.EI_ID_PROFESSIONAL
,v02.EI_ID_FIRST_NURSE_RESP
,v02.EI_ID_ROOM
,v02.EI_ID_DEP_CLIN_SERV
,v02.ACUITY
,v02.COLOR_TEXT
,v02.TRIAGE_FLG_LETTER
,v02.ID_TRIAGE_COLOR
,v02.RANK_ACUITY
,v02.ID_FIRST_NURSE_RESP
,v02.DT_FIRST_OBS_TSTZ
,v02.EPIS_INFO_FLG_STATUS
,v02.EI_ID_SCHEDULE
,v02.GT_ID_EPISODE
,v02.GT_DRUG_PRESC
,v02.GT_ICNP_INTERVENTION
,v02.GT_NURSE_ACTIVITY
,v02.GT_INTERVENTION
,v02.GT_MONITORIZATION
,v02.GT_TEACH_REQ
,v02.GT_MOVEMENT
,v02.GT_DISCHARGE_PEND
,v02.OTH_EXAM_N
,v02.OTH_EXAM_D
,v02.IMG_EXAM_N
,v02.IMG_EXAM_D
,v02.OPINION_STATE
,v02.PAT_GENDER
,v02.ID_PATIENT
,v02.EI_NICK_NAME
,v02.EI_NAME
,v02.ID_EPIS_TYPE
,v02.SYS_INSTITUTION
,v02.SYS_LANG
,v02.SYS_SOFTWARE
,v02.SYS_PROF_ID
,v02.SYS_LPROF
,v02.SYS_YES
,v02.SYS_NO
,v02.id_discharge
,v02.flg_status_discharge
,v02.dt_med_tstz
,v02.dt_pend_tstz
,v02.dt_admin_tstz
FROM V_GRID_CDOC_DISCHARGE v02
where v02.e_flg_status = alert_context('g_epis_status_inactive')
AND v02.dt_end_tstz > cast( (current_timestamp - numtodsinterval( alert_context('l_edis_timelimit'), 'HOUR') ) as timestamp with local time zone );
