-- CHANGED BY: Susana Silva
-- CHANGE DATE: 26/11/2009 11:23
-- CHANGE REASON: [ALERT-12334] 
grant select, insert, update, delete, references, alter, index on SUPPLY_WORKFLOW to ALERT_VIEWER;
-- CHANGE END: Susana Silva

-- CHANGED BY: Suelmar Zanetti Castro
-- CHANGE DATE: 11/02/2014 09:46
-- CHANGE REASON: CODING-1823
GRANT SELECT ON SUPPLY_WORKFLOW TO ALERT_CODING_TR;
-- CHANGE END: Suelmar Zanetti Castro