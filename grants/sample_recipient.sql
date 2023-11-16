-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SAMPLE_RECIPIENT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-05-16
-- CHANGE REASON: [CEMR-1493] [Subtask] [CNT] DB alert_core_cnt_api.sample_recipient and alert_core_cnt.sample_recipient
grant select, insert, update on alert.sample_recipient to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai