-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 10/05/2011 16:05
-- CHANGE REASON: [ALERT-177865] 
-- Grant/Revoke object privileges 
grant select, insert, update, delete on VACC_MANUFACTURER_INST_SOFT to ALERT_CONFIG;
grant select on VACC_MANUFACTURER_INST_SOFT to ALERT_DEFAULT;
grant select, update, delete on VACC_MANUFACTURER_INST_SOFT to ALERT_RESET;
grant select on VACC_MANUFACTURER_INST_SOFT to INTER_ALERT_V2;
-- CHANGE END: Rita Lopes