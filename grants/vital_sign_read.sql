-- CHANGED BY: Jos� Brito
-- CHANGE DATE: 19/12/2014 14:49
-- CHANGE REASON: [ALERT-304997] [MEDICATION] Patient weight - Versioning DDL
GRANT REFERENCES ON VITAL_SIGN_READ TO ALERT_PRODUCT_TR;
-- CHANGE END: Jos� Brito

-- CHANGED BY: Jos� Brito
-- CHANGE DATE: 22/12/2014 12:15
-- CHANGE REASON: [ALERT-304997] [MEDICATION] Patient weight - Versioning DDL
GRANT SELECT ON VITAL_SIGN_READ TO ALERT_INTER;
-- CHANGE END: Jos� Brito

-- CHANGED BY: Ruben Araujo
-- CHANGE DATE: 24/05/2016 
-- CHANGE REASON: [ALERT-320400] 
GRANT SELECT  ON ALERT.VITAL_SIGN_READ to ALERT_PRODUCT_TR ;
-- CHANGE END: Ruben Araujo
