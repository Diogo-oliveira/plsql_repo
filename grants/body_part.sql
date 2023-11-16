-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 06/08/2010 11:36
-- CHANGE REASON: [ALERT-111044] 
grant references on BODY_PART to ALERT_DEFAULT;
-- CHANGE END:  Mauro Sousa


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-28
-- CHANGED REASON: CEMR-1467

-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-05-08
-- CHANGE REASON: [CEMR-1437] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_intervention and alert_core_cnt.pk_cnt_intervention
GRANT SELECT ON ALERT.BODY_PART TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Amanda Lee
-- CHANGE END: Ana Moita
