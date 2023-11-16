CREATE OR REPLACE VIEW V_GRID_CDOC_DISCHARGE AS
SELECT vbase.E_ID_DEPARTMENT
,vbase.E_ID_VISIT
,vbase.V_ID_ORIGIN
,vbase.ID_INSTITUTION
,vbase.ID_VISIT
,vbase.E_FLG_EHR
,vbase.E_DT_BEGIN_TSTZ
,vbase.dt_end_tstz
,vbase.E_FLG_STATUS
,vbase.E_ID_EPISODE
,vbase.E_ID_FAST_TRACK
,vbase.dt_begin_tstz
,vbase.e_dt_cancel_tstz
,vbase.EI_ID_EPISODE
,vbase.EI_ID_SOFTWARE
,vbase.EI_ID_PROFESSIONAL
,vbase.EI_ID_FIRST_NURSE_RESP
,vbase.EI_ID_ROOM
,vbase.EI_ID_DEP_CLIN_SERV
,vbase.ACUITY
,vbase.COLOR_TEXT
,vbase.TRIAGE_FLG_LETTER
,vbase.ID_TRIAGE_COLOR
,vbase.RANK_ACUITY
,vbase.ID_FIRST_NURSE_RESP
,vbase.DT_FIRST_OBS_TSTZ
,vbase.EPIS_INFO_FLG_STATUS
,vbase.EI_ID_SCHEDULE
,vbase.GT_ID_EPISODE
,vbase.GT_DRUG_PRESC
,vbase.GT_ICNP_INTERVENTION
,vbase.GT_NURSE_ACTIVITY
,vbase.GT_INTERVENTION
,vbase.GT_MONITORIZATION
,vbase.GT_TEACH_REQ
,vbase.GT_MOVEMENT
,vbase.GT_DISCHARGE_PEND
,vbase.OTH_EXAM_N
,vbase.OTH_EXAM_D
,vbase.IMG_EXAM_N
,vbase.IMG_EXAM_D
,vbase.OPINION_STATE
,vbase.PAT_GENDER
,vbase.ID_PATIENT
,vbase.EI_NICK_NAME
,vbase.EI_NAME
,vbase.ID_EPIS_TYPE
,vbase.SYS_INSTITUTION
,vbase.SYS_LANG
,vbase.SYS_SOFTWARE
,vbase.SYS_PROF_ID
,vbase.SYS_LPROF
,vbase.SYS_YES
,vbase.SYS_NO
,d.id_discharge id_discharge
,d.flg_status flg_status_discharge
,d.dt_med_tstz
,d.dt_pend_tstz
,d.dt_admin_tstz
      FROM v_grid_cdoc_base vbase
      JOIN discharge d
        ON d.id_episode = vbase.ei_id_episode;
