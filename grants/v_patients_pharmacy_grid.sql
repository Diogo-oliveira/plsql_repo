-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 17/06/2016 15:22
-- CHANGE REASON: [ALERT-322314] Report for medication dispensation - "Prescriptions médicamenteuses validées"
BEGIN
    pk_versioning.run('GRANT SELECT ON v_patients_pharmacy_grid TO alert_pharmacy_func WITH GRANT OPTION');
END;
/
-- CHANGE END: rui.mendonca