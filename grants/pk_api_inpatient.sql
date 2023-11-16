GRANT EXECUTE ON ALERT.PK_API_INPATIENT TO ALERT_VIEWER;
-- issue ALERT-41949
GRANT EXECUTE ON ALERT.PK_API_INPATIENT TO INTF_ALERT;



-- CHANGED BY: Luís Maia
-- CHANGE DATE: 15/09/2009 10:47
-- CHANGE REASON: [ALERT-43377] Added grant to package PK_API_INPATIENT on alert_adtcod
grant execute on pk_api_inpatient to alert_adtcod;
-- CHANGE END: Luís Maia

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 01/04/2010 12:31
-- CHANGE REASON: [ALERT-85877] US profiles: corrections
grant execute on pk_api_inpatient for intf_alert;
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 01/04/2010 17:42
-- CHANGE REASON: [  ALERT-85877] 
grant execute on pk_api_inpatient to intf_alert;
-- CHANGE END: Sofia Mendes