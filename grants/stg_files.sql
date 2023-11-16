-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 05/07/2010 16:16
-- CHANGE REASON: [ALERT-109378] 
grant select on STG_FILES to ALERT_VIEWER;
grant select on STG_FILES to INTER_ALERT;
grant select, insert, update, delete, references, alter, index on STG_FILES to INTER_ALERT_V2;
-- CHANGE END: Tércio Soares