-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 14/09/2011
-- CHANGE REASON: ALERT-194969
GRANT SELECT ON V_INTERVENTION TO ALERT_INTER;
-- CHANGE END:  Nuno Neves



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-28
-- CHANGED REASON: CEMR-1467

-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-05-08
-- CHANGE REASON: [CEMR-1437] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_intervention and alert_core_cnt.pk_cnt_intervention
GRANT SELECT ON V_INTERVENTION TO ALERT_CORE_CNT_API  WITH GRANT OPTION;
-- CHANGE END: Amanda Lee

-- CHANGE END: Ana Moita