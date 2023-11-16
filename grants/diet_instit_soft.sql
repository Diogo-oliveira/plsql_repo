-- CHANGED BY: Susana Silva
-- CHANGE DATE: 04/03/2010 16:45
-- CHANGE REASON: [ALERT-79356] 
grant select on DIET_INSTIT_SOFT to ALERT_DEFAULT;
-- CHANGE END: Susana Silva


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.DIET_INSTIT_SOFT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-6-13
-- CHANGED REASON: EMR-1425

grant select, insert, update on alert.diet_instit_soft to alert_core_cnt with grant option;
-- CHANGE END: Ricardo Meira
