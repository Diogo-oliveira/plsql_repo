-- CHANGED BY: Filipa Moura
-- CHANGE DATE: 20/04/2010 15:15
-- CHANGE REASON: SECAUTH-1160 

GRANT EXECUTE ON ALERT.PK_ALERTS TO ALERT_IDP;

-- cmf 17-05-2013
GRANT EXECUTE ON ALERT.PK_ALERTS TO finger_db;

-- cmf 06-11-2014
grant execute on ALERT.PK_ALERTS to ALERT_INTER with grant option;



-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 17/02/2017 15:50
-- CHANGE REASON: [ALERT-328098]
GRANT EXECUTE ON PK_ALERTS TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Henriques