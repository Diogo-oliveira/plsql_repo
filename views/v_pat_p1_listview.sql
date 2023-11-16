CREATE or REPLACE VIEW V_PAT_P1_LISTVIEW AS
SELECT t."ID_P1",t."NUM_REQ",t."DT_P1",t."FLG_TYPE",t."PROF_REQUESTED_NAME",t."ID_PATIENT",t."PAT_NAME",t."PAT_GENDER",t."PAT_AGE",t."PHOTO",t."INST_DEST_NAME",t."DEST_DEPARTMENT",t."CLIN_SRV_NAME",t."P1_SPEC_NAME",t."TYPE_ICON",t."FLG_STATUS",t."FLG_STATUS_DESC",t."STATUS_ICON",t."STATUS_RANK",t."STATUS_COLORS",t."PRIORITY_INFO",t."PRIORITY_DESC",t."PRIORITY_ICON",t."DT_SCHEDULE",t."HOUR_SCHEDULE",t."DT_SCH_MILLIS",t."DT_ELAPSED",t."ID_SCHEDULE",t."INST_ORIG_NAME",t."FLG_EDITABLE",t."FLG_TASK_EDITABLE",t."DESC_DAY",t."DESC_DAYS",t."DATE_FIELD",t."DT_SERVER",t."CAN_CANCEL",t."CAN_SENT",t."OBSERVATIONS",t."ID_REP_DUPLICATA",t."ID_REP_REPRINT",t."ID_TASK_TYPE",t."ID_CODIFICATION",t."DT_ORDER", t."FLG_MIGRATED",
  alert_context('i_lang') l_lang,
  alert_context('i_prof_id') l_id_professional,
  alert_context('i_prof_institution') l_id_institution,
	alert_context('i_prof_software') l_id_software
  FROM TABLE(pk_p1_ext_sys.get_pat_p1(i_lang       => alert_context('i_lang'),
                                      i_prof       => profissional(alert_context('i_prof_id'),
                                                                   alert_context('i_prof_institution'),
                                                                   alert_context('i_prof_software')),
                                      i_id_patient => alert_context('i_id_patient'),
                                      i_type       => alert_context('i_type'))) t;
