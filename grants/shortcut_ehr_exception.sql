-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 21/09/2011 15:19
-- CHANGE REASON: [ALERT-196265 ] 
-- Grant/Revoke object privileges 
grant select on SHORTCUT_EHR_EXCEPTION to ALERT_DEFAULT;
grant select, update, delete on SHORTCUT_EHR_EXCEPTION to ALERT_RESET;
grant select on SHORTCUT_EHR_EXCEPTION to ALERT_VIEWER;
grant select, insert, update, delete, references, alter, index on SHORTCUT_EHR_EXCEPTION to INTER_ALERT_V2;
-- CHANGE END: Sérgio Santos