GRANT REFERENCES ON vital_sign TO alert_default;

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 28/08/2009 16:51
-- CHANGE REASON: [ALERT-40932] 
GRANT REFERENCES ON vital_sign TO alert_default;
-- CHANGE END: Tércio Soares

-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 02/06/2010 15:39
-- CHANGE REASON: [ALERT-101704] 
GRANT SELECT ON vital_sign TO alert_default;
-- CHANGE END:  Mauro Sousa

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 07/05/2014 09:01
-- CHANGE REASON: [ALERT-283775] 
grant select on vital_sign to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.vital_sign to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes