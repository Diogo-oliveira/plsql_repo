-- CHANGED BY: S�rgio Cunha
-- CHANGE DATE: 15/10/2014 10:24
-- CHANGE REASON: [ALERT-297325] 
grant references on INTERVENTION to ALERT_PRODUCT_MT;
-- CHANGE END: S�rgio Cunha

-- CHANGED BY: S�rgio Cunha
-- CHANGE DATE: 15/10/2014 10:28
-- CHANGE REASON: [ALERT-297325] 
grant references on INTERVENTION to ALERT_PRODUCT_MT;
-- CHANGE END: S�rgio Cunha


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-28
-- CHANGED REASON: CEMR-1467

-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-05-08
-- CHANGE REASON: [CEMR-1437] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_intervention and alert_core_cnt.pk_cnt_intervention
GRANT SELECT, INSERT, UPDATE ON ALERT.INTERVENTION TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Amanda Lee
-- CHANGE END: Ana Moita



-- CHANGED BY: Adriana Salgueiro
-- CHANGED DATE: 2020-1-20
-- CHANGED REASON: EMR-25501

 GRANT SELECT ON INTERVENTION TO ALERT_DEFAULT;
-- CHANGE END: Adriana Salgueiro
