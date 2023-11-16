-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:58
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references, select on WF_STATUS to alert_product_tr;
grant references, select on WF_STATUS to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references, select on WF_STATUS to alert_product_tr;
grant references, select on WF_STATUS to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 09:35
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
GRANT SELECT,REFERENCES ON ALERT.wf_status TO ALERT_PHARMACY_DATA;
-- CHANGE END: Alexis Nascimento

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 16:56
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
grant references, select on WF_STATUS to alert_pharmacy_func;
GRANT SELECT ON WF_STATUS TO alert_pharmacy_func;
-- CHANGE END: Alexis Nascimento

-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 18/01/2016 10:29
-- CHANGE REASON: [ALERT-317861] Medication&Pharmacy - Product
GRANT REFERENCES, SELECT ON wf_status TO alert_product_mt WITH GRANT OPTION;
-- CHANGE END: rui.mendonca

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 17/02/2017 15:03
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON wf_status TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/03/2017 15:04
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON wf_status TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes