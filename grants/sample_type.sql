-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SAMPLE_TYPE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1718

-- CHANGED BY: Webber Chiou
-- CHANGED DATE: 2018/05/17
-- CHANGE REASON: [CEMR-1491] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api_sample_type and alert_core_cnt.pk_cnt_sample_type
GRANT SELECT, INSERT ON alert.sample_type TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Webber Chiou
-- CHANGE END: Ana Moita
