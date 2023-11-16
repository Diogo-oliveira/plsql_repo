-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on seq_doc_template_context to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-26
-- CHANGED REASON: CEMR-1903

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-01
-- CHANGE REASON: [CEMR-1632] [Subtask] [CNT] DB alert_core_cnt.doc_template and alert_core_cnt_api.pk_cnt_doc_template 
grant select on alert.seq_doc_template_context to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita
