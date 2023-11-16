-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 06-APR-2011
-- CHANGE REASON: [ALERT-171286] 
grant select, update, delete on PN_EPIS_REASON to alert_reset;
-- CHANGE END: Ana Coelho

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON pn_epis_reason to apex_alert_default;
/
-- CHANGE END: Nuno Alves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.PN_EPIS_REASON to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
