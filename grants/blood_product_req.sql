-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 13/09/2018 11:05
-- CHANGE REASON: [EMR-6418] 
grant select on BLOOD_PRODUCT_REQ to ADW_STG;
grant select on BLOOD_PRODUCT_REQ to ADW_STG_P1;
grant select on BLOOD_PRODUCT_REQ to ADW_STG_SCHDLR;
grant select, insert, delete on BLOOD_PRODUCT_REQ to ALERT_APEX_TOOLS;
grant select on BLOOD_PRODUCT_REQ to ALERT_AT_VIEWER;
grant select, references on BLOOD_PRODUCT_REQ to ALERT_CODING_TR;
grant select, insert, update, delete on BLOOD_PRODUCT_REQ to ALERT_CONFIG;
grant select on BLOOD_PRODUCT_REQ to ALERT_INTER;
grant select, update, delete on BLOOD_PRODUCT_REQ to ALERT_RESET;
grant select, insert, update, delete on BLOOD_PRODUCT_REQ to ALERT_ROLE_DML;
grant select on BLOOD_PRODUCT_REQ to ALERT_ROLE_RO;
grant select, references, alter, index, debug on BLOOD_PRODUCT_REQ to ALERT_VIEWER;
grant select on BLOOD_PRODUCT_REQ to AUDIT_TRAIL_VIEWER;
grant select on BLOOD_PRODUCT_REQ to DSV;
grant select on BLOOD_PRODUCT_REQ to DSVCNT;
grant select, insert, update, delete, references, alter, index, debug on BLOOD_PRODUCT_REQ to INTER_ALERT_V2;
-- CHANGE END: Pedro Henriques

-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 15/07/2022 08:09
-- CHANGE REASON: [EMR-54080]
GRANT SELECT ON blood_product_req TO ALERT_INTER WITH GRANT OPTION;
-- CHANGE END: Pedro Henriques