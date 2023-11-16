-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SEQ_EXAM_CAT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/05/17
-- CHANGE REASON: [CEMR-1492] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api_exam_cat and alert_core_cnt.pk_cnt_exam_cat
GRANT SELECT ON alert.seq_exam_cat TO alert_core_cnt;
-- CHANGE END: Webber Chiou