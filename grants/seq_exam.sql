-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SEQ_EXAM to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-23
-- CHANGED REASON: CEMR-1835

-- CHANGED BY: Howard Cheng
-- CHANGE DATE: 2018-05-28
-- CHANGE REASON: CEMR-1590 [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api.exam and alert_core_cnt.pk_cnt_exam
GRANT SELECT ON ALERT.SEQ_EXAM TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Howard Cheng
-- CHANGE END: Ana Moita