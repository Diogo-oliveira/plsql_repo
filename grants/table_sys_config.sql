

  GRANT SELECT ON ALERT.SYS_CONFIG TO ALERT_VIEWER;

  grant select on alert.sys_config to aol;
  
  GRANT SELECT ON ALERT.SYS_CONFIG TO ALERT_AT_VIEWER;

  -- CHANGED BY: Diamantino Campos
-- CHANGE DATE: 10-12-2010
-- CHANGE REASON: SCH-3434
grant select on alert.sys_config to ALERT_APSSCHDLR_TR;

-- CHANGE END