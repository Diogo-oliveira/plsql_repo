-- CHANGED BY: Jos� Brito
-- CHANGE DATE: 17/09/2009 14:31
-- CHANGE REASON: [ALERT-44274] Group triage colors
GRANT SELECT ON ALERT.TRIAGE_COLOR_GROUP TO ALERT_VIEWER;
-- CHANGE END: Jos� Brito


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-12-10
-- CHANGED REASON: EMR-9798
GRANT SELECT ON triage_color_group TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso
