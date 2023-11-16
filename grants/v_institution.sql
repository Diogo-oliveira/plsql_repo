-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 21/03/2009 16:33
-- CHANGE REASON: [ALERT-19860] Interface views
grant select on V_INSTITUTION to alert_adtcod, intf_alert;
-- CHANGE END

-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 05-Feb-2010
-- CHANGE REASON: ALERT-78089
GRANT SELECT ON V_INSTITUTION TO alert_adtcod, intf_alert, inter_alert_v2;
-- CHANGE END: Paulo Fonseca


-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2010-12-10
-- CHANGE REASON: ADT-3775

GRANT SELECT ON v_institution TO alert_basecomp;

-- CHANGE END: Bruno Martins