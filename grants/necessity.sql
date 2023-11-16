-- CHANGED BY: Susana Silva
-- CHANGE DATE: 04/03/2010 16:16
-- CHANGE REASON: [ALERT-79339 ] 
grant select on NECESSITY to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2014-09-12
-- CHANGE REASON: ADT-8484

grant select on necessity to alert_adtcod with grant option;

-- CHANGED END: Bruno Martins


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.NECESSITY to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
