-- CHANGED BY: Susana Silva
-- CHANGE DATE: 05/03/2010 11:17
-- CHANGE REASON: [ALERT-79485] 
grant select, references on SYSTEM_ORGAN to ALERT_DEFAULT;
-- CHANGE END: Susana Silva


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-28
-- CHANGED REASON: CEMR-1467

-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-05-23
-- CHANGE REASON: [CEMR-1437] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_intervention and alert_core_cnt.pk_cnt_intervention
GRANT SELECT ON system_organ to ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Amanda Lee
-- CHANGE END: Ana Moita
