-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:04
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT, INSERT, UPDATE, DELETE ON PN_CONFIG_DESCRIPTION TO APEX_ALERT_DEFAULT;
/
-- CHANGE END: Nuno Alves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant DELETE on ALERT.PN_CONFIG_DESCRIPTION to ALERT_APEX_TOOLS;
grant INSERT on ALERT.PN_CONFIG_DESCRIPTION to ALERT_APEX_TOOLS;
grant SELECT on ALERT.PN_CONFIG_DESCRIPTION to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.PN_CONFIG_DESCRIPTION to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
