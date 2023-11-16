-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 19-Jul-2010
-- CHANGE REASON: ALERT-112811
GRANT SELECT ON ds_cmpt_mkt_rel TO alert_viewer;
-- CHANGE END: Paulo Fonseca

-- CHANGED BY: Nuno Amorim
-- CHANGE DATE: 14-08-2019 17:21
-- CHANGE REASON: EMR-18887
GRANT SELECT ON ds_cmpt_mkt_rel TO alert_adtcod;
-- CHANGE END: Nuno Amorim

-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 12/09/2019 16:42
-- CHANGE REASON: [EMR-18265] - [ADT-DB] Patient ID in HTML5 - Versioning
grant select on alert.ds_cmpt_mkt_rel to alert_adtcod;
-- CHANGE END: Anna Kurowska