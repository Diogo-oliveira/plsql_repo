

  GRANT SELECT ON ALERT.TRANSLATION TO ALERT_VIEWER;
GRANT SELECT ON ALERT.TRANSLATION TO ALERT_AT_VIEWER;

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 25-03-2010
-- CHANGE REASON: SCH-458
grant select, references on TRANSLATION to basecomp;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 25-03-2010
-- CHANGE REASON: SCH-458
grant select on TRANSLATION to basecomp;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 25-03-2010
-- CHANGE REASON: SCH-458
grant select on TRANSLATION to alert_basecomp;
-- CHANGE END: Telmo Castro
