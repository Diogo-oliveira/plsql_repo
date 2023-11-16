grant select on alert.currency to alert_viewer;

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on CURRENCY to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: José Brito
-- CHANGE DATE: 14/01/2015 16:27
-- CHANGE REASON: [ALERT-306202] [DB] Unit price - Versioning - 01
GRANT REFERENCES ON CURRENCY TO ALERT_PRODUCT_TR;
GRANT REFERENCES ON CURRENCY TO ALERT_PRODUCT_MT;
-- CHANGE END: José Brito

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 09-FEV-2017
-- CHANGE REASON: ALERT-328743
grant SELECT on CURRENCY to ALERT_APEX_TOOLS;
-- CHANGE END: Luis Fernandes
