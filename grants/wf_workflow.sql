-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant references on WF_WORKFLOW to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on WF_WORKFLOW to alert_product_mt;
-- CHANGE END: Pedro Quinteiro



-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 09:32
-- CHANGE REASON: [ALERT-296372] ALERTÂ® PHARMACY: New pharmacist profile
grant references on WF_WORKFLOW to alert_pharmacy_data;
-- CHANGE END: Alexis Nascimento

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 16:56
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
GRANT SELECT ON WF_WORKFLOW TO alert_pharmacy_func;
-- CHANGE END: Alexis Nascimento