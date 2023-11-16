-- CHANGED BY:  sergio.dias
-- CHANGE DATE: 29/07/2010 12:26
-- CHANGE REASON: [ALERT-116048] 
GRANT SELECT ON ALERT.REHAB_AREA TO ALERT_VIEWER;
-- CHANGE END:  sergio.dias

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on rehab_area to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-26
-- CHANGED REASON: CEMR-1903

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-01
-- CHANGE REASON: [CEMR-1632] [Subtask] [CNT] DB alert_core_cnt.doc_template and alert_core_cnt_api.pk_cnt_doc_template
grant select on alert.rehab_area to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita
