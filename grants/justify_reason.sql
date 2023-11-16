-- CHANGED BY: Sérgio Cunha
-- CHANGE DATE: 29/10/2009 04:46
-- CHANGE REASON: [ALERT-52263] 
-- Grant/Revoke object privileges 
grant select, references on JUSTIFY_REASON to ALERT_ADTCOD;
grant select on JUSTIFY_REASON to ALERT_DEFAULT;
grant select, update, delete on JUSTIFY_REASON to ALERT_RESET;
grant select on JUSTIFY_REASON to ALERT_VIEWER;
-- CHANGE END: Sérgio Cunha

-- CHANGED BY: Sérgio Cunha
-- CHANGE DATE: 30/10/2009 15:07
-- CHANGE REASON: [ALERT-52263] 
grant select on JUSTIFY_REASON to ALERT_DEFAULT;
grant select on JUSTIFY_REASON to ALERT_VIEWER;
-- CHANGE END: Sérgio Cunha