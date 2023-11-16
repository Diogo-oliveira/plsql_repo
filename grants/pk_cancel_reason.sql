-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2014-04-08
-- CHANGE REASON: ADT-8075

grant execute on PK_CANCEL_REASON to alert_adtcod;

-- CHANGED END: Bruno Martins

-- CHANGED BY:  Rui Mendonça
-- CHANGE DATE: 31/05/2016 14:25
-- CHANGE REASON: [ALERT-321699] PK_PRESC_MED.GET_CLINICAL_PURPOSE_LIST performance improvement and do not show diagnosis information
GRANT EXECUTE ON pk_cancel_reason TO alert_product_tr;
-- CHANGE END:  Rui Mendonça

-- CHANGED BY:  Adriana Ramos
-- CHANGE DATE: 11/02/2019
-- CHANGE REASON: [EMR-11427] Dispense tab: show the institution and expire validation/dispense records
GRANT EXECUTE ON pk_cancel_reason TO alert_pharmacy_func;
-- CHANGE END:  Adriana Ramos

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/06/2022 09:49
-- CHANGE REASON: [EMR-53854]
GRANT EXECUTE ON pk_cancel_reason TO alert_product_mt;
-- CHANGE END: Sofia Mendes