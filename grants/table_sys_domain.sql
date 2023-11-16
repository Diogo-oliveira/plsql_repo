

  GRANT SELECT ON ALERT.SYS_DOMAIN TO ALERT_VIEWER;
GRANT SELECT ON ALERT.SYS_DOMAIN TO ALERT_AT_VIEWER;

 -- CHANGED BY: Telmo Castro
-- CHANGE DATE: 25-03-2010
-- CHANGE REASON: SCH-458
 grant select, references on sys_domain to alert_apsschdlr_mt;
-- CHANGE END: Telmo Castro

 -- CHANGED BY: Telmo Castro
-- CHANGE DATE: 25-03-2010
-- CHANGE REASON: SCH-458
 grant select on sys_domain to alert_apsschdlr_mt;
-- CHANGE END: Telmo Castro
