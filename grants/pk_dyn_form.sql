

-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 13/09/2019 11:52
-- CHANGE REASON: [EMR-18265] - [ADT-DB] Patient ID in HTML5
grant execute on pk_dyn_form to alert_adtcod;
-- CHANGE END: Anna Kurowska

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 09/01/2020 11:17
-- CHANGE REASON: [EMR-25257] - AO | Pharmacy integration with CPOE
BEGIN
pk_versioning.run('grant EXECUTE on pk_dyn_form to ALERT_PHARMACY_FUNC with grant option');
END;
/

--
-- CHANGE END: Sofia Mendes