-- CHANGED BY: Susana Silva
-- CHANGE DATE: 13/10/2009 17:20
-- CHANGE REASON: [ALERT-44922 ] 
grant select on PROFILE_TEMPLATE_MARKET to ALERT_DEFAULT;
grant select, insert, update, delete, references, alter, index on PROFILE_TEMPLATE_MARKET to ALERT_VIEWER;
-- CHANGE END: Susana Silva

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 24/07/2014 09:21
-- CHANGE REASON: [ALERT-291210] 
grant select on profile_template_market to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON profile_template_market to apex_alert_default;
/
-- CHANGE END: Nuno Alves

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.profile_template_market to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes