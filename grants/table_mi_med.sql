grant select on MI_MED to ALERT_VIEWER;


-- CHANGED BY: T�rcio Soares
-- CHANGE DATE: 09/04/2010 11:42
-- CHANGE REASON: [ALERT-87226] 
GRANT REFERENCES ON MI_MED TO alert_default;
-- CHANGE END: T�rcio Soares

GRANT SELECT ON MI_MED TO INTF_ALERT;