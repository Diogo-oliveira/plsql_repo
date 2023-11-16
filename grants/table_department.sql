

  GRANT SELECT ON ALERT.DEPARTMENT TO ALERT_VIEWER;

  --RicardoNunoAlmeida  
--22-05-2009
--ALERT-29522
GRANT SELECT ON ALERT.DEPARTMENT TO FINGER_DB;
--END RNA

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-07-2010
-- CHANGE REASON: APS-518
grant select on alert.department to alert_apsschdlr_mt;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 21-12-2010
-- CHANGE REASON: SCH-3800
grant select on ALERT.department to alert_apsschdlr_tr;
-- CHANGE END: Telmo Castro