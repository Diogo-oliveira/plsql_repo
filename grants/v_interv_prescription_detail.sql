GRANT SELECT ON V_INTERV_PRESCRIPTION_DETAIL TO INTF_ALERT;
GRANT SELECT ON V_INTERV_PRESCRIPTION_DETAIL TO ALERT_ADTCOD;


-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/11/2021 08:44
-- CHANGE REASON: [EMR-49451]
GRANT SELECT ON v_interv_prescription_detail TO alert_inter WITH GRANT OPTION;
-- CHANGE END: Ana Matos