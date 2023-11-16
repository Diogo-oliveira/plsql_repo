-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 16/04/2010 15:46
-- CHANGE REASON: [ALERT-89937] 
-- Grant/Revoke object privileges 
grant select on SCALES_ACTION_GROUP to ALERT_DEFAULT;
grant select, update, delete on SCALES_ACTION_GROUP to ALERT_RESET;
grant select on SCALES_ACTION_GROUP to ALERT_VIEWER;
grant select, insert, update, delete, references, alter, index on SCALES_ACTION_GROUP to INTER_ALERT_V2;
grant select, insert, update, delete, references on SCALES_ACTION_GROUP to PIX;
-- CHANGE END: Rita Lopes