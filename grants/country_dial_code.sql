

-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 26/08/2019 12:50
-- CHANGE REASON: [EMR-18187] - [ADT-DB] Patient ID - country dial code table
grant select on alert.country_dial_code to alert_adtcod;
grant select on alert.country_dial_code to alert_adtcod_cfg;
-- CHANGE END: Anna Kurowska

-- CHANGED BY: André Silva
-- CHANGE DATE: 09/09/2019
-- CHANGE REASON: [EMR-20771] - Phone dial code in patient identification is not autopopulated
grant references on country_dial_code to alert_adtcod;
-- CHANGE END: André Silva