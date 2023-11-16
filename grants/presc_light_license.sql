

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 21/09/2020 12:06
-- CHANGE REASON: [EMR-34832]
GRANT SELECT ON ALERT.PRESC_LIGHT_LICENSE TO ALERT_PRODUCT_TR;
-- CHANGE END: Cristina Oliveira

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 15/12/2020 10:33
-- CHANGE REASON: [EMR-39746]
grant select, references on presc_light_license to adw_stg  WITH GRANT OPTION;
-- CHANGE END: Cristina Oliveira

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 28/01/2021 08:39
-- CHANGE REASON: [EMR-41232]
GRANT SELECT ON presc_light_license TO alert_product_tr WITH GRANT OPTION;
-- CHANGE END: Cristina Oliveira