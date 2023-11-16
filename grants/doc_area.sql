-- CHANGED BY: Susana Silva
-- CHANGE DATE: 08/03/2010 19:06
-- CHANGE REASON: [ALERT-80019] 
grant select, references on DOC_AREA to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 09/05/2014 17:31
-- CHANGE REASON: [ALERT-283653] 
grant select on doc_area  to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on  doc_area  to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON doc_area to apex_alert_default;
/
-- CHANGE END: Nuno Alves

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.doc_area to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-27
-- CHANGED REASON: CEMR-1903

grant select on alert.doc_area to alert_core_cnt with grant option;

-- CHANGE END: Ana Moita
