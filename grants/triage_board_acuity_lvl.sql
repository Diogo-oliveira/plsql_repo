-- CHANGED BY: Jos� Silva
-- CHANGE DATE: 03/05/2012 18:42
-- CHANGE REASON: [ALERT-229201] EST simplified triage
GRANT SELECT ON ALERT.TRIAGE_BOARD_ACUITY_LVL TO ALERT_VIEWER;
-- CHANGE END: Jos� Silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-12-10
-- CHANGED REASON: EMR-9798
GRANT SELECT, INSERT, UPDATE ON triage_board_acuity_lvl TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso