-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 23/11/2011
-- CHANGE REASON: ALERT-206286 
GRANT REFERENCES ON ALERT.ORDER_TYPE TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Teixeira

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/08/2018 16:19
-- CHANGE REASON: [EMR-5733 ] New development in Medication orders with co-sign
grant references on order_type to alert_product_mt;
-- CHANGE END: Sofia Mendes