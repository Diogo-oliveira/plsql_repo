-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 21/04/2010 11:26
-- CHANGE REASON: [ALERT-91154] Registration POS
GRANT SELECT ON SR_POS_PHARM_DET TO ALERT_VIEWER;
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.SR_POS_PHARM_DET to alert_reset;
-- CHANGE END: Ana Coelho