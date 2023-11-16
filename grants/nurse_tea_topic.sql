-- CHANGED BY: DIOGO OLIVEIRA
-- CHANGE DATE: 21/10/2017
GRANT SELECT ON nurse_tea_topic TO ALERT_INTER;
-- CHANGE END: DIOGO OLIVEIRA


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-8-3
-- CHANGED REASON: CEMR-1914

grant select, insert, update on alert.nurse_tea_topic to alert_core_cnt with grant option;

-- CHANGE END: Ana Moita
