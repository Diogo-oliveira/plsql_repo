-- CHANGED BY: Pedro Miranda
-- CHANGE DATE: 02/06/2014
-- CHANGE REASON: [ALERT-286603]
grant all on analysis_sample_type to alert_inter;
-- CHANGE END: Pedro Miranda



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.ANALYSIS_SAMPLE_TYPE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1892

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-05-16
-- CHANGE REASON: [CEMR-1460] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_analysis and alert_core_cnt.pk_cnt_analysis
grant select, insert, update on alert.analysis_sample_type to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita
