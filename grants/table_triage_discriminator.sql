

  GRANT SELECT ON ALERT.TRIAGE_DISCRIMINATOR TO ALERT_VIEWER;





-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-12-10
-- CHANGED REASON: EMR-9798
GRANT SELECT, INSERT, UPDATE ON triage_discriminator TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso