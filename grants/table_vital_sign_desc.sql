

  GRANT SELECT ON ALERT.VITAL_SIGN_DESC TO ALERT_VIEWER;





-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-12-10
-- CHANGED REASON: EMR-9798
GRANT SELECT ON vital_sign_desc TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso
