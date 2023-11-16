-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 11/12/2009 17:02
-- CHANGE REASON: [ALERT-61892] CPOE 2nd phase
grant select on EPIS_POSITIONING_DET_HIST to ALERT_VIEWER;
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.EPIS_POSITIONING_DET_HIST to alert_reset;
-- CHANGE END: Ana Coelho