-- CHANGED BY: Susana Silva
-- CHANGE DATE: 05/03/2010 11:17
-- CHANGE REASON: [ALERT-79485] 
grant select on SR_INTERVENTION to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Pedro Miranda
-- CHANGE DATE: 09/05/2014 05:31
-- CHANGE REASON: [ALERT-284224]
grant all on sr_intervention to alert_inter;
-- CHANGE END: Pedro Miranda



-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on sr_intervention to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Kátia Marques
-- CHANGE DATE: 13-10-2014
-- CHANGE REASON: APS-437 (Codes) Problem with migration of event codes and standards. 
grant select on sr_intervention to ALERT_APSSCHDLR_TR;
-- CHANGE END: Kátia Marques