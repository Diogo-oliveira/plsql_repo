-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:58
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on ACTION to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on ACTION to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on ACTION to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 14:42
-- CHANGE REASON: [ALERT-206805] 
GRANT SELECT ON ACTION TO ALERT_PRODUCT_MT;
GRANT SELECT ON ACTION TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 16:56
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
GRANT SELECT ON ACTION TO alert_pharmacy_func;
-- CHANGE END: Alexis Nascimento

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON action to apex_alert_default;
/
-- CHANGE END: Nuno Alves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.ACTION to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
