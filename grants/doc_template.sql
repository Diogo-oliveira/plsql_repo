GRANT REFERENCES ON doc_template TO alert_default;

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 28/08/2009 16:51
-- CHANGE REASON: [ALERT-40932] 
GRANT REFERENCES ON doc_template TO alert_default;
-- CHANGE END: Tércio Soares

-- CHANGED BY: Daniel Conceicao
-- CHANGED DATE: 2011-Feb-07
-- CHANGED REASON: ALERT-159918 

grant select on doc_template to alert_default;

-- CHANGE END: Daniel Conceicao

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 09/05/2014 17:31
-- CHANGE REASON: [ALERT-283653] 
grant select on doc_template  to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on doc_template to alert_apex_tools;
-- CHANGE END:  luis.r.silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant DELETE on ALERT.DOC_TEMPLATE to ALERT_APEX_TOOLS;
grant INSERT on ALERT.DOC_TEMPLATE to ALERT_APEX_TOOLS;
grant UPDATE on ALERT.DOC_TEMPLATE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: luis.fernandes
-- CHANGE DATE: 29/06/2017 15:05
-- CHANGE REASON: [ALERT-331729] 
grant select, insert, delete on alert.doc_template to alert_apex_tools_content;
-- CHANGE END: luis.fernandes


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-26
-- CHANGED REASON: CEMR-1903

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-01
-- CHANGE REASON: [CEMR-1632] [Subtask] [CNT] DB alert_core_cnt.doc_template and alert_core_cnt_api.pk_cnt_doc_template
grant select on alert.doc_template to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita
