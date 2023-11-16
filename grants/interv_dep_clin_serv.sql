-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:58
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on INTERV_DEP_CLIN_SERV to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on INTERV_DEP_CLIN_SERV to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on interv_dep_clin_serv to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-28
-- CHANGED REASON: CEMR-1467

-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-05-08
-- CHANGE REASON: [CEMR-1437] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_intervention and alert_core_cnt.pk_cnt_intervention
GRANT SELECT, INSERT, DELETE ON INTERV_DEP_CLIN_SERV TO ALERT_CORE_CNT WITH GRANT OPTION;
-- CHANGE END: Amanda Lee
-- CHANGE END: Ana Moita
