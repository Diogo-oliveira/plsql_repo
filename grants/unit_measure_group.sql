-- CHANGED BY: Ariel Geraldo Machado
-- CHANGED DATE: 2009-JUN-29
-- CHANGED REASON: ALERT-12013 - Keypad's with unit of measures on Touch-option templates
GRANT SELECT ON unit_measure_group TO alert_viewer;
-- CHANGE END: Ariel Geraldo Machado

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.unit_measure_group to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-8-23
-- CHANGED REASON: EMR-5494

grant select, insert, update on alert.unit_measure_group to alert_core_cnt with grant option;

-- CHANGE END: Ana Moita
