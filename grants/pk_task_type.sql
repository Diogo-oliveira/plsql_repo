-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 26/11/2013 14:07
-- CHANGE REASON: [ALERT-267338] 
grant execute on pk_task_type to alert_viewer;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 05/12/2013 10:55
-- CHANGE REASON: [ALERT-271385] 
grant execute on alert.pk_task_type to alert_viewer;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2014-04-08
-- CHANGE REASON: ADT-8075

grant execute on PK_TASK_TYPE to alert_adtcod;

-- CHANGED END: Bruno Martins

-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 30/10/2014 09:47
-- CHANGE REASON: [ALERT-300272] 
grant all on pk_task_type to ALERT_CORE_DATA;
-- CHANGE END: mario.mineiro