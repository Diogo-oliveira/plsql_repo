GRANT SELECT ON V_INTERV_PRESCRIPTION_PLAN TO INTF_ALERT;
GRANT SELECT ON V_INTERV_PRESCRIPTION_PLAN TO ALERT_ADTCOD;


-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/11/2021 08:44
-- CHANGE REASON: [EMR-49451]
GRANT SELECT ON v_interv_prescription_plan TO alert_inter WITH GRANT OPTION;
-- CHANGE END: Ana Matos