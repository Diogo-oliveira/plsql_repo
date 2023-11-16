-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 05/07/2010 10:33
-- CHANGE REASON: [ALERT-109173] 
grant select on INSTITUTION_FIELD_DATA to ALERT_VIEWER;
grant select, update, delete on INSTITUTION_FIELD_DATA to ALERT_RESET;
-- CHANGE END: Tércio Soares

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2013-11-07
-- CHANGE REASON: ADT-7863

grant select on institution_field_data to alert_adtcod;

-- CHANGED END: Bruno Martins