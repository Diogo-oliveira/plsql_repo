-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 26-Feb-2010
-- CHANGE REASON: ALERT-77799
grant select on V_BED_TYPE to intf_alert, inter_alert_v2;
-- CHANGE END: Paulo Fonseca


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 22/11/2010 15:06
-- CHANGE REASON: [ALERT-142288] [INPATIENT]: APS/SCH - Data Migration
GRANT SELECT ON V_BED_TYPE TO alert_apsschdlr_tr;
-- CHANGE END: Sofia Mendes