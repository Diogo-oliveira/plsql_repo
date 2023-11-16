-- CHANGED BY: Susana Silva
-- CHANGE DATE: 26/11/2009 10:04
-- CHANGE REASON: [ALERT-12334] 
grant select, insert, update, delete, references, alter, index on SUPPLY_CONTEXT to ALERT_VIEWER;
-- CHANGE END: Susana Silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SUPPLY_CONTEXT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
