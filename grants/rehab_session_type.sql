-- CHANGED BY:  sergio.dias
-- CHANGE DATE: 29/07/2010 15:15
-- CHANGE REASON: [ALERT-116048] 
GRANT SELECT ON ALERT.REHAB_SESSION_TYPE TO ALERT_VIEWER;
-- CHANGE END:  sergio.dias

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 11-APR-2010
-- CHANGE REASON: [ALERT-171286] 
grant references on REHAB_SESSION_TYPE to alert_reset;
-- CHANGE END: Ana Coelho


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.REHAB_SESSION_TYPE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso