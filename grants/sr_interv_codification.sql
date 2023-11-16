-- CHANGED BY: hugo.madureira
-- CHANGE DATE: 2014-09-30
-- CHANGE REASON: CODING-2441
grant select on SR_INTERV_CODIFICATION to ALERT_CODING_TR with grant option;
-- CHANGE END: hugo.madureira

-- CHANGED BY: Kátia Marques
-- CHANGE DATE: 13-10-2014
-- CHANGE REASON: APS-437 (Codes) Problem with migration of event codes and standards.
grant select on sr_interv_codification to ALERT_APSSCHDLR_TR;
-- CHANGE END: Kátia Marques