grant select on epis_pn to ALERT_VIEWER; 

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.EPIS_PN to alert_reset;
-- CHANGE END: Ana Coelho