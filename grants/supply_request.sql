-- CHANGED BY: Susana Silva
-- CHANGE DATE: 26/11/2009 11:00
-- CHANGE REASON: [ALERT-12334] 
grant select, insert, update, delete, references, alter, index on SUPPLY_REQUEST to ALERT_VIEWER;
-- CHANGE END: Susana Silva

-- CHANGED BY: Suelmar Zanetti Castro
-- CHANGE DATE: 11/02/2014 09:47
-- CHANGE REASON: CODING-1823
GRANT SELECT ON SUPPLY_REQUEST TO ALERT_CODING_TR;
-- CHANGE END: Suelmar Zanetti Castro

-- CHANGED BY: Diogo Oliveira
GRANT SELECT ON supply_request TO ALERT_INTER;
-- CHANGE END: Diogo Oliveira
