-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 29/05/2014 08:15
-- CHANGE REASON: [ALERT-283483] 
grant select, references on sys_button to alert_core_data;
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON sys_button to apex_alert_default;
/
-- CHANGE END: Nuno Alves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SYS_BUTTON to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
