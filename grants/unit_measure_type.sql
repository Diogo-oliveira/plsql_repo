-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 16/08/2016 12:11
-- CHANGE REASON: [ALERT-324179 ] Medication: lnk_um_supp_exceptions correct FK
grant references on UNIT_MEASURE_TYPE to alert_product_mt;
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.unit_measure_type to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-8-23
-- CHANGED REASON: EMR-5494

grant select, insert, update on alert.unit_measure_type to alert_core_cnt with grant option;

-- CHANGE END: Ana Moita
