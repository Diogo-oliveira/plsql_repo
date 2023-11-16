-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 01/04/2010 16:32
-- CHANGE REASON: [ALERT-85843] 
grant references on SCH_EVENT to ALERT_DEFAULT;
-- CHANGE END: Tércio Soares

-- CREATE BY: Telmo
-- CREATE DATE: 29-03-2011
-- CREATE REASON: APS-1486
grant select on sch_event to alert_apsschdlr_mt;
-- CHANGE END: Telmo


-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on sch_event to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY:  André Silva
-- CHANGE DATE: 18/01/2017
-- CHANGE REASON: ALERT-326669
grant select on sch_event to alert_inter;
-- CHANGE END:  André Silva

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.sch_event to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-26
-- CHANGED REASON: CEMR-1903

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-01
-- CHANGE REASON: [CEMR-1632] [Subtask] [CNT] DB alert_core_cnt.doc_template and alert_core_cnt_api.pk_cnt_doc_template
grant select on alert.sch_event to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita
