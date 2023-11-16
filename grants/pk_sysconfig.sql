-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant execute on pk_sysconfig  to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant execute on pk_sysconfig  to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 14:42
-- CHANGE REASON: [ALERT-206805] 
GRANT EXECUTE ON PK_SYSCONFIG TO ALERT_PRODUCT_MT;
GRANT EXECUTE ON PK_SYSCONFIG TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Pinheiro
-- CHANGE DATE: 02-04-2012
-- CHANGE REASON: ARCDB-1132
grant execute on pk_sysconfig to public;
-- CHANGE END: Pedro Pinheiro

-- CHANGED BY: Andre Silva
-- CHANGE DATE: 02-01-2018
-- CHANGE REASON: [ALERT-72304]
grant execute on pk_sysconfig to alert_coding_tr;
-- CHANGE END: Andre Silva