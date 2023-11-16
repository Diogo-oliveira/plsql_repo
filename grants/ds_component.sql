-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 19-Jul-2010
-- CHANGE REASON: ALERT-112811
GRANT SELECT ON ds_component TO alert_viewer;
-- CHANGE END: Paulo Fonseca


-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 12/09/2019 16:42
-- CHANGE REASON: [EMR-18265] - [ADT-DB] Patient ID in HTML5 - Versioning
grant select on alert.ds_component to alert_adtcod;
-- CHANGE END: Anna Kurowska