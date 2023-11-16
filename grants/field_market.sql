-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 05/07/2010 09:50
-- CHANGE REASON: [ALERT-109173] 
grant select, update, delete on FIELD_MARKET to ALERT_RESET;
grant select on FIELD_MARKET to ALERT_VIEWER;
-- CHANGE END: Tércio Soares

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2013-11-07
-- CHANGE REASON: ADT-7863

grant select on field_market to alert_adtcod;

-- CHANGED END: Bruno Martins