-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-JUN-2011
-- CHANGE REASON: [ALERT-183808] 
grant select, update, delete on cdr_call to alert_reset;
-- CHANGE END: Ana Coelho

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 12-01-2012
-- CHANGE REASON: ALERT-213711 New medication DB Architecture modification
grant references on cdr_call to alert_product_tr;
-- CHANGE END: Pedro Quinteiro