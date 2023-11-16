
-- CHANGED BY: Rui Marante
-- CHANGE DATE: 01/06/2011
-- CHANGE REASON: [PM-788]

--ALERT_PRODUCT_TR
grant execute on t_cls_pha_order to alert_product_tr;

-- CHANGE END [PM-788]

-- CHANGED BY: rui.mendonca
-- CHANGE DATE: ../05/2013
-- CHANGE REASON: ALERT-256089 || Medication and other- prescription edition screen- PRN Reason- Blood Glucose < 50 - incorrect description (missing < 50 ).
--
GRANT EXECUTE ON pk_string_utils TO alert_product_tr;
-- CHANGE END: rui.mendonca