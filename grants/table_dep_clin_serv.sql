

  GRANT SELECT ON ALERT.DEP_CLIN_SERV TO ALERT_VIEWER;

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-07-2010
-- CHANGE REASON: APS-518
grant select on alert.dep_clin_serv to alert_apsschdlr_mt;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 21-12-2010
-- CHANGE REASON: SCH-3800
grant select on ALERT.dep_clin_serv to alert_apsschdlr_tr;
-- CHANGE END: Telmo Castro
