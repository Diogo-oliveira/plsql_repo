-- CHANGED BY: Susana Silva
-- CHANGE DATE: 08/03/2010 19:06
-- CHANGE REASON: [ALERT-80019] 
grant select, references on SYS_SHORTCUT to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on SYS_SHORTCUT to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant select on sys_shortcut to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 11/11/2014 12:29
-- CHANGE REASON: [ALERT-297153 ] 
grant SELECT  on sys_shortcut to alert_product_tr;
-- CHANGE END: Alexis Nascimento

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON sys_shortcut to apex_alert_default;
/
-- CHANGE END: Nuno Alves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SYS_SHORTCUT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
