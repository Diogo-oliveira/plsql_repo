-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 13/09/2018 11:07
-- CHANGE REASON: [EMR-6418] 
grant select on BLOOD_PRODUCT_ANALYSIS to ADW_STG;
grant select on BLOOD_PRODUCT_ANALYSIS to ADW_STG_P1;
grant select on BLOOD_PRODUCT_ANALYSIS to ADW_STG_SCHDLR;
grant select, insert, delete on BLOOD_PRODUCT_ANALYSIS to ALERT_APEX_TOOLS;
grant select on BLOOD_PRODUCT_ANALYSIS to ALERT_AT_VIEWER;
grant select, insert, update, delete on BLOOD_PRODUCT_ANALYSIS to ALERT_CONFIG;
grant select on BLOOD_PRODUCT_ANALYSIS to ALERT_INTER;
grant select, update, delete on BLOOD_PRODUCT_ANALYSIS to ALERT_RESET;
grant select, insert, update, delete on BLOOD_PRODUCT_ANALYSIS to ALERT_ROLE_DML;
grant select on BLOOD_PRODUCT_ANALYSIS to ALERT_ROLE_RO;
grant select, references, alter, index, debug on BLOOD_PRODUCT_ANALYSIS to ALERT_VIEWER;
grant select on BLOOD_PRODUCT_ANALYSIS to AUDIT_TRAIL_VIEWER;
grant select on BLOOD_PRODUCT_ANALYSIS to DSV;
grant select on BLOOD_PRODUCT_ANALYSIS to DSVCNT;
grant select, insert, update, delete, references, alter, index, debug on BLOOD_PRODUCT_ANALYSIS to INTER_ALERT_V2;
-- CHANGE END: Pedro Henriques