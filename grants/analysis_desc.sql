-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.ANALYSIS_DESC to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1891

-- CHANGED BY: Webber Chiou
-- CHANGE DATE: 2018-06-21
-- CHANGE REASON: [CEMR-1460] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_analysis and alert_core_cnt.pk_cnt_analysis
grant select, insert on alert.analysis_desc to alert_core_cnt with grant option;
-- CHANGE END: Webber Chiou

-- CHANGE END: Ana Moita
