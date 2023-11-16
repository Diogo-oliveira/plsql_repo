-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 13/09/2018 11:06
-- CHANGE REASON: [EMR-6418] 
grant select on BLOOD_PRODUCTS_EA to ADW_STG;
grant select on BLOOD_PRODUCTS_EA to ADW_STG_P1;
grant select on BLOOD_PRODUCTS_EA to ADW_STG_SCHDLR;
grant select, insert, delete on BLOOD_PRODUCTS_EA to ALERT_APEX_TOOLS;
grant select, insert, update, delete on BLOOD_PRODUCTS_EA to ALERT_CONFIG;
grant select on BLOOD_PRODUCTS_EA to ALERT_INTER;
grant select, update, delete on BLOOD_PRODUCTS_EA to ALERT_RESET;
grant select on BLOOD_PRODUCTS_EA to ALERT_VIEWER;
grant select on BLOOD_PRODUCTS_EA to DSV;
-- CHANGE END: Pedro Henriques

-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 08/04/2021 14:05
-- CHANGE REASON: [EMR-43787] - Link mother automatically generated lab tests to the blood transfusion of the son
grant select on blood_products_ea to alert_inter with grant option;
-- CHANGE END: Diogo Oliveira