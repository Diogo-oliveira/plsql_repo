-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 11/01/2016 17:18
-- CHANGE REASON: [ALERT-317715] Medication&Pharmacy: transactional model corrections
grant references on co_sign_hist to alert_product_tr with grant option;
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 01/11/2017
GRANT SELECT ON co_sign TO ALERT_INTER;
-- CHANGE END: Diogo Oliveira