
  GRANT SELECT ON ALERT.COMPLAINT_ALERT_DIAGNOSIS TO ALERT_VIEWER;




-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-07-12
-- CHANGED REASON: EMR-4688
GRANT SELECT, INSERT, UPDATE, DELETE ON complaint_alert_diagnosis TO alert_core_func WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso