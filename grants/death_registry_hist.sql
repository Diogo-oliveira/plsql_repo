-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 19-Jul-2010
-- CHANGE REASON: ALERT-112811
GRANT SELECT ON death_registry_hist TO alert_viewer;
-- CHANGE END: Paulo Fonseca

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.DEATH_REGISTRY_HIST to alert_reset;
-- CHANGE END: Ana Coelho