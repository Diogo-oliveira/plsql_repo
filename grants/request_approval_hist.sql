-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 03/07/2010 20:36
-- CHANGE REASON: [ALERT-109286] 
GRANT SELECT ON request_approval_hist TO alert_viewer;
GRANT ALTER,DELETE,INDEX,INSERT,REFERENCES,SELECT,UPDATE ON request_approval_hist TO inter_alert_v2;
-- CHANGE END: Sérgio Santos