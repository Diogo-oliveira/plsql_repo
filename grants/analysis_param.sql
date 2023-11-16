-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.ANALYSIS_PARAM to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1891

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-05-16
-- CHANGE REASON: [CEMR-1461] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_analysis_param and alert_core_cnt.pk_cnt_analysis_param
grant select, insert, update on alert.analysis_param to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/05/2020 09:30
-- CHANGE REASON: [EMR-31935] - Ability to view a specific lab test result while prescribing medication
grant references on ANALYSIS_PARAM to ALERT_PRODUCT_MT;
-- CHANGE END: Sofia Mendes