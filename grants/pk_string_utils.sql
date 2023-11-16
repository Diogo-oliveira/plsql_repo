-- CHANGED BY: Bruno Pereira
-- CHANGE DATE: 19/09/2014 
-- CHANGE REASON: [ALERT-295949] 
GRANT EXECUTE ON PK_STRING_UTILS TO ALERT_INTER;
-- CHANGE END: Bruno Pereira


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/02/2016 16:34
-- CHANGE REASON: [ALERT-316371 ] Medication backoffice debug
grant  execute on pk_string_utils to alert_product_mt;
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 01/06/2018 11:47
-- CHANGE REASON: [EMR-3812] Ability to display multiple lines for patient instructions with arabic characters in ambulatory dispense labels for SA market
grant execute on pk_string_utils to alert_pharmacy_func;
-- CHANGE END: Sofia Mendes