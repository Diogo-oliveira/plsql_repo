-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 05/07/2010 16:22
-- CHANGE REASON: [ALERT-109378] 
grant select on STG_EXT_PROF_CAT to ALERT_INTER;
grant select on STG_EXT_PROF_CAT to INTER_ALERT;
grant select, insert, update, delete, references, alter, index on STG_EXT_PROF_CAT to INTER_ALERT_V2;
-- CHANGE END: Tércio Soares