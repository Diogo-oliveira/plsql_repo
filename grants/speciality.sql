-- CHANGED BY: Susana Silva
-- CHANGE DATE: 05/03/2010 11:17
-- CHANGE REASON: [ALERT-79485] 
grant select, references on speciality to ALERT_DEFAULT;
-- CHANGE END: Susana Silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SPECIALITY to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: WEBBER CHIOU
-- CHANGED DATE: 2018/06/06
-- CHANGE REASON: [CEMR-1628] [SUBTASK] [CNT] DB ALERT_CORE_CNT_API.PK_CNT_API_SPECIALITY AND ALERT_CORE_CNT.PK_CNT_SPECIALITY
GRANT SELECT, INSERT ON ALERT.SPECIALITY TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: WEBBER CHIOU