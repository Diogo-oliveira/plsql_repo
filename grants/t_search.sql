-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 18:14
-- CHANGE REASON: [ALERT-206929]
GRANT EXECUTE ON T_SEARCH TO ALERT_INTER;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 29/11/2011 16:12
-- CHANGE REASON: [ALERT-207707] 9.5/9.6 - Start Date é obrigatória, mas OK está activo.jpg
--
grant execute on t_search to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 14/1122011 07:48
-- CHANGE REASON: [ALERT-209694] Missing grant
--
grant execute on t_search to alert_product_mt;
-- CHANGE END: Rui Spratley