-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 27/04/2015 11:03
-- CHANGE REASON: [ALERT-310275] ALERT-310275 The system must not allow other user than the prescriber to cancel or discontinue one order without co-sign
grant execute on pk_co_sign to alert_product_tr;
-- CHANGE END: Nuno Alves