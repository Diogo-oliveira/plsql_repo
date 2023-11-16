GRANT REFERENCES ON sample_text TO alert_default;

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 28/08/2009 16:51
-- CHANGE REASON: [ALERT-40932] 
GRANT REFERENCES ON sample_text TO alert_default;
-- CHANGE END: Tércio Soares

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 28/10/2011 17:01
-- CHANGE REASON: [ALERT-202443] 
grant select on SAMPLE_TEXT to alert_default;
-- CHANGE END: Sérgio Santos


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1891

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-18
-- CHANGE REASON: [CEMR-1461] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_analysis_param and alert_core_cnt.pk_cnt_analysis_param
grant select on alert.sample_text to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita
