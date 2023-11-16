GRANT REFERENCES ON category TO alert_default;

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 28/08/2009 16:51
-- CHANGE REASON: [ALERT-40932] 
GRANT REFERENCES ON category TO alert_default;
-- CHANGE END: Tércio Soares

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references on CATEGORY to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 15:44
-- CHANGE REASON: [ALERT-206850] 
GRANT SELECT,REFERENCES ON CATEGORY TO ALERT_PRODUCT_MT;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 17:50
-- CHANGE REASON: [ALERT-206929] 
GRANT SELECT,REFERENCES ON CATEGORY TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 17:50
-- CHANGE REASON: [ALERT-206929] 
GRANT SELECT,REFERENCES ON SYS_CONFIG TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 09/12/2013 14:07
-- CHANGE REASON: [ALERT-271432] 
grant select, references on category to alert_core_data;
-- CHANGE END: Rui Spratley

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 09/05/2014 17:31
-- CHANGE REASON: [ALERT-283653] 
grant select on category to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on category to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON category to apex_alert_default;
/
-- CHANGE END: Nuno Alves

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 26/01/2017 08:27
-- CHANGE REASON: [ALERT-328195 ] 
GRANT SELECT ON CATEGORY TO ALERT_INTER;
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.category to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes