-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant DELETE on ALERT.EXAM_CAT to ALERT_APEX_TOOLS;
grant INSERT on ALERT.EXAM_CAT to ALERT_APEX_TOOLS;
grant SELECT on ALERT.EXAM_CAT to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.EXAM_CAT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: André Silva
-- CHANGED DATE: 2018-3-05
-- CHANGED REASON: EMR-3120
GRANT SELECT ON alert.exam_cat TO alert_inter;
-- CHANGE END: André Silva
-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/05/17
-- CHANGE REASON: [CEMR-1492] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api_exam_cat and alert_core_cnt.pk_cnt_exam_cat
GRANT SELECT, INSERT ON alert.exam_cat TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Webber Chiou