-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 02/12/2010 17:04
-- CHANGE REASON: [ALERT-146441] Associate a surgical procedure to supplies
GRANT SELECT ON ALERT.SR_RESERV_REQ_TO_SUPPLY TO ALERT_VIEWER;
-- CHANGE END: Filipe Silva

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.SR_RESERV_REQ_TO_SUPPLY to alert_reset;
-- CHANGE END: Ana Coelho