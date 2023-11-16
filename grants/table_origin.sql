

  GRANT SELECT ON ALERT.ORIGIN TO ALERT_VIEWER;


-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 25-03-2010
-- CHANGE REASON: SCH-458
grant select, references on origin to schdlr;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 25-03-2010
-- CHANGE REASON: SCH-458
grant select on origin to schdlr;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 07-04-2010
-- CHANGE REASON: SCH-512
grant select on origin to ALERT_APSSCHDLR_MT;
-- CHANGE END: Telmo Castro