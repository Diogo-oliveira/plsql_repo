-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 05/12/2013 10:55
-- CHANGE REASON: [ALERT-271385] 
grant execute on alert.pk_patient to alert_core_tech;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 08/06/2016 15:59
-- CHANGE REASON: [ALERT-321408] API to return patient barcode
GRANT EXECUTE ON PK_PATIENT TO ADW_STG;
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 17/01/2017 15:36
-- CHANGE REASON: [ALERT-326926] 
GRANT EXECUTE ON ALERT.PK_PATIENT TO ALERT_INTER;
-- CHANGE END: Vanessa Barsottelli


-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 17/02/2017 15:50
-- CHANGE REASON: [ALERT-328098]
GRANT EXECUTE ON PK_PATIENT TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Henriques

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/01/2018 15:02
-- CHANGE REASON: [ALERT-335196 ] Cars
grant execute on alert.pk_patient to alert_pharmacy_func;
-- CHANGE END: Sofia Mendes