-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 25/03/2010 14:08
-- CHANGE REASON: [ALERT-63591] Registration of complications through templates in use at JBZ (JBZ will provide the templates).
GRANT SELECT ON ALERT.COMPLICATION TO ALERT_VIEWER;
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 31/10/2011 16:42
-- CHANGE REASON: [ALERT-202623] select granted
grant select on complication to alert_default;
-- CHANGE END: Pedro Carneiro


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.COMPLICATION to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
