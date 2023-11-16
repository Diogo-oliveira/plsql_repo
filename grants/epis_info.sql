-- CHANGED BY: André Silva
-- CHANGE DATE: 18/01/2017 
-- CHANGE REASON: ALERT-326669 
GRANT SELECT  ON EPIS_INFO to ALERT_INTER;
-- CHANGE END: André Silva

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 21/02/2017 11:03
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON epis_info TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/03/2017 15:03
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON epis_info TO alert_product_tr WITH GRANT OPTION');
END;
/
-- CHANGE END: Sofia Mendes