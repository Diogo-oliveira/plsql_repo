-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 05/12/2012 10:08
-- CHANGE REASON: [ALERT-229347] alert default references
grant references on complaint to ALERT_DEFAULT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on complaint to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.complaint to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-26
-- CHANGED REASON: CEMR-1903

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-01
-- CHANGE REASON: [CEMR-1632] [Subtask] [CNT] DB alert_core_cnt.doc_template and alert_core_cnt_api.pk_cnt_doc_template
grant select on alert.complaint to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita



-- CHANGED BY: Adriana Salgueiro
-- CHANGED DATE: 2020-5-6
-- CHANGED REASON: EMR-31318

grant select on alert.complaint to alert_default;
-- CHANGE END: Adriana Salgueiro



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2012-01-29
-- CHANGED REASON: EMR-41373
GRANT SELECT ON complaint TO alert_core_func WITH GRANT OPTION;
GRANT SELECT ON complaint TO alert_core_data WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso
