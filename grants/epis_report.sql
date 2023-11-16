-- CHANGED BY: goncalo.almeida
-- CHANGE DATE: 31/08/2010 14:50
-- CHANGE REASON: ALERT-121123
GRANT UPDATE ON alert.epis_report TO alert_viewer;
-- CHANGE END: goncalo.almeida



-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references,select on EPIS_REPORT to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references,select on ORDER_TYPE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro