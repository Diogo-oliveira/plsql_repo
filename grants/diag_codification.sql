-- CHANGED BY: Daniel Ferreira
-- CHANGE DATE: 04/07/2014
-- CHANGE REASON: [CODING-1282] 
grant select on DIAG_CODIFICATION to ALERT_CODING_MT with grant option;
-- CHANGE END: Daniel Ferreira

GRANT SELECT, INSERT, UPDATE, DELETE ON DIAG_CODIFICATION to ALERT_APEX_TOOLS;

--
grant select on alert.DIAG_CODIFICATION to alert_inter;
