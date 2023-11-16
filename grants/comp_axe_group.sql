-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 25/03/2010 14:09
-- CHANGE REASON: [ALERT-63591] Registration of complications through templates in use at JBZ (JBZ will provide the templates).
GRANT SELECT ON ALERT.COMP_AXE_GROUP TO ALERT_VIEWER;
-- CHANGE END: Alexandre Santos


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.COMP_AXE_GROUP to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
