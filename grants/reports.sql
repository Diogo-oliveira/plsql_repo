-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 26/01/2011 11:49
-- CHANGE REASON: [ALERT-157923] 
grant references on REPORTS to ALERT_DEFAULT;
-- CHANGE END:  Mauro Sousa

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 04/07/2011 16:59
-- CHANGE REASON: [ALERT-157923] grants needed to FK references
grant references on REPORTS to ALERT_DEFAULT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 20/09/2011 18:02
-- CHANGE REASON: [ALERT-157923] grants
grant references on REPORTS to ALERT_DEFAULT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 27/01/2012 17:16
-- CHANGE REASON: [ALERT-216286] 
grant references on REPORTS to ALERT_DEFAULT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON reports to apex_alert_default;
/
-- CHANGE END: Nuno Alves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.REPORTS to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

grant select on ALERT.REPORTS to ALERT_DEFAULT;