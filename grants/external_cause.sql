-- CHANGED BY: Susana Silva
-- CHANGE DATE: 04/03/2010 16:27
-- CHANGE REASON: 
grant select on EXTERNAL_CAUSE to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Telmo
-- CHANGE DATE: 19-06-2014
-- CHANGE REASON: CODING_2027
grant select on external_cause to alert_coding_tr with grant option;
--CHANGE END: Telmo


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.EXTERNAL_CAUSE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
