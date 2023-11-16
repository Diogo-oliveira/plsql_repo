-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:58
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on WF_ACTION to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on WF_ACTION to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 14:42
-- CHANGE REASON: [ALERT-206805] 
GRANT REFERENCES,SELECT ON WF_ACTION TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 16:56
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
GRANT SELECT ON WF_ACTION TO alert_pharmacy_func;
-- CHANGE END: Alexis Nascimento