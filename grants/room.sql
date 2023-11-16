-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant INSERT on ALERT.ROOM to ALERT_APEX_TOOLS;
grant SELECT on ALERT.ROOM to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.ROOM to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2018-2-2
-- CHANGED REASON: EMR-822

BEGIN
    pk_versioning.run('grant select on alert.bed to alert_product_tr');
END;
/
-- CHANGE END: Joao Coutinho



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-24
-- CHANGED REASON: CEMR-1892

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-05-16
-- CHANGE REASON: [CEMR-1460] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_analysis and alert_core_cnt.pk_cnt_analysis
grant select on alert.room to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita
