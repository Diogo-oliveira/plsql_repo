-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 13/09/2018 11:06
-- CHANGE REASON: [EMR-6418] 
grant select on HEMO_TYPE_INSTIT_SOFT to ADW_STG;
grant select on HEMO_TYPE_INSTIT_SOFT to ADW_STG_P1;
grant select on HEMO_TYPE_INSTIT_SOFT to ADW_STG_SCHDLR;
grant select, insert, delete on HEMO_TYPE_INSTIT_SOFT to ALERT_APEX_TOOLS;
grant select on HEMO_TYPE_INSTIT_SOFT to ALERT_AT_VIEWER;
grant select, insert, update, delete on HEMO_TYPE_INSTIT_SOFT to ALERT_CONFIG;
grant select on HEMO_TYPE_INSTIT_SOFT to ALERT_INTER;
grant select, update, delete on HEMO_TYPE_INSTIT_SOFT to ALERT_RESET;
grant select, insert, update, delete on HEMO_TYPE_INSTIT_SOFT to ALERT_ROLE_DML;
grant select on HEMO_TYPE_INSTIT_SOFT to ALERT_ROLE_RO;
grant select, references, alter, index, debug on HEMO_TYPE_INSTIT_SOFT to ALERT_VIEWER;
grant select on HEMO_TYPE_INSTIT_SOFT to AUDIT_TRAIL_VIEWER;
grant select on HEMO_TYPE_INSTIT_SOFT to DSV;
grant select on HEMO_TYPE_INSTIT_SOFT to DSVCNT;
grant select, insert, update, delete, references, alter, index, debug on HEMO_TYPE_INSTIT_SOFT to INTER_ALERT_V2;
-- CHANGE END: Pedro Henriques