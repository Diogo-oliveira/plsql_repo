-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 17/08/2016 14:52
-- CHANGE REASON: [ALERT-322808] Medication alias per institution
BEGIN
    pk_versioning.run('GRANT EXECUTE ON t_tab_product_search TO alert_product_mt WITH GRANT OPTION');
    pk_versioning.run('GRANT EXECUTE ON t_tab_product_search TO alert_product_tr WITH GRANT OPTION');
    pk_versioning.run('GRANT EXECUTE ON t_tab_product_search TO alert_inter WITH GRANT OPTION');
END;
/
-- CHANGE END: rui.mendonca