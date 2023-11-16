-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 05/07/2010 16:24
-- CHANGE REASON: [ALERT-109378] 
grant select on STG_INSTITUTION_FIELD_DATA to ALERT_INTER;
grant select on STG_INSTITUTION_FIELD_DATA to INTER_ALERT;
grant select, insert, update, delete, references, alter, index on STG_INSTITUTION_FIELD_DATA to INTER_ALERT_V2;
-- CHANGE END: Tércio Soares