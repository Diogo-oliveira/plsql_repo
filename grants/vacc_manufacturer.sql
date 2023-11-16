-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 10/05/2011 16:03
-- CHANGE REASON: [ALERT-177865] 
-- Grant/Revoke object privileges 
grant select, insert, update, delete on VACC_MANUFACTURER to ALERT_CONFIG;
grant select on VACC_MANUFACTURER to ALERT_DEFAULT;
grant select, update, delete on VACC_MANUFACTURER to ALERT_RESET;
grant select on VACC_MANUFACTURER to INTER_ALERT_V2;
-- CHANGE END: Rita Lopes

-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 10/05/2011 18:22
-- CHANGE REASON: [ALERT-177865] 
grant select on VACC_MANUFACTURER to ALERT_VIEWER;
-- CHANGE END: Rita Lopes


-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-7-20
-- CHANGED REASON: CEMR-1881

-- CHANGED BY: Howard Cheng
-- CHANGED DATE: 2018/06/13
-- CHANGE REASON: [CEMR-1683] DB alert_core_cnt_api.pk_cnt_api.vaccine and alert_core_cnt.pk_cnt_vaccine
GRANT SELECT, INSERT ON vacc_manufacturer TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Howard Cheng
-- CHANGE END: Ricardo Meira
