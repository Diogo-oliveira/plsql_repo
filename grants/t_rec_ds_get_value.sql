

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 09/01/2020 11:17
-- CHANGE REASON: [EMR-25257] - AO | Pharmacy integration with CPOE
BEGIN
pk_versioning.run('grant EXECUTE on t_rec_ds_get_value to ALERT_PHARMACY_FUNC with grant option');
END;
/
-- CHANGE END: Sofia Mendes