-- CHANGED BY: Jos� Brito
-- CHANGE DATE: 24/01/2010 19:51
-- CHANGE REASON: [ALERT-70160] Triage refactoring
GRANT SELECT ON ALERT.TRIAGE_ESI_LEVEL TO ALERT_VIEWER;
-- CHANGE END: Jos� Brito


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-12-10
-- CHANGED REASON: EMR-9798
GRANT SELECT, INSERT, UPDATE ON triage_esi_level TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso
