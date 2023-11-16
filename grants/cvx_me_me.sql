-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 13/05/2011 10:36
-- CHANGE REASON: [ALERT-178956] 
-- Grant/Revoke object privileges 
grant select, insert, update, delete on CVX_ME_MED to ALERT_CONFIG;
grant select on CVX_ME_MED to ALERT_DEFAULT;
grant select, insert, update, delete, references, alter, index on CVX_ME_MED to ALERT_PRODUCT_MT;
grant select on CVX_ME_MED to ALERT_REPORTS;
grant select, update, delete on CVX_ME_MED to ALERT_RESET;
grant select, insert, update, delete on CVX_ME_MED to ALERT_SUPPORT;
grant select on CVX_ME_MED to ALERT_VIEWER;
grant select on CVX_ME_MED to ALERT_VIEWER_TEMP;
grant select on CVX_ME_MED to DSV;
grant select, insert, update, delete, references, alter, index on CVX_ME_MED to INTER_ALERT_V2;
-- CHANGE END: Rita Lopes

-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 13/05/2011 11:45
-- CHANGE REASON: [ALERT-178956] 
-- Grant/Revoke object privileges 
grant select, insert, update, delete on CVX_ME_MED to ALERT_CONFIG;
grant select on CVX_ME_MED to ALERT_DEFAULT;
grant select on CVX_ME_MED to ALERT_REPORTS;
grant select on CVX_ME_MED to ALERT_VIEWER;
grant select, insert, update, delete, references, alter, index on CVX_ME_MED to INTER_ALERT_V2;
-- CHANGE END: Rita Lopes

-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 13/05/2011 12:08
-- CHANGE REASON: [ALERT-178956] 
-- Grant/Revoke object privileges 
grant select, insert, update, delete on CVX_ME_MED to ALERT_CONFIG;
grant select on CVX_ME_MED to ALERT_DEFAULT;
grant select on CVX_ME_MED to ALERT_VIEWER;
grant select, insert, update, delete, references, alter, index on CVX_ME_MED to INTER_ALERT_V2;
-- CHANGE END: Rita Lopes