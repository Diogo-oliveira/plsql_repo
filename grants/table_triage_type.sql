

  GRANT ALTER ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT DELETE ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT INDEX ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT INSERT ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT SELECT ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT UPDATE ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;


  GRANT REFERENCES ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT ON COMMIT REFRESH ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT QUERY REWRITE ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT DEBUG ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;

  GRANT FLASHBACK ON ALERT.TRIAGE_TYPE TO ALERT_VIEWER;





-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-12-10
-- CHANGED REASON: EMR-9798
GRANT SELECT ON triage_type TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso
