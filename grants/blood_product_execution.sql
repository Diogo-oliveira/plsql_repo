-- CHANGED BY: Andre Silva
-- CHANGE DATE: 13/09/2018
-- CHANGE REASON: EMR-6445
grant select on BLOOD_PRODUCT_EXECUTION to ALERT_INTER;
-- CHANGE END: Andre Silva

-- CHANGED BY: Andre Silva
-- CHANGE DATE: 13/09/2018
-- CHANGE REASON: EMR-6445
GRANT ALL ON BLOOD_PRODUCT_EXECUTION TO ALERT_INTER WITH GRANT OPTION;
-- CHANGE END: Andre Silva

-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 08/04/2021 14:05
-- CHANGE REASON: [EMR-43787] - Link mother automatically generated lab tests to the blood transfusion of the son
grant select on blood_product_execution to alert_inter with grant option;
-- CHANGE END: Diogo Oliveira