-- CHANGED BY: S�rgio Santos
-- CHANGE DATE: 03/07/2010 20:30
-- CHANGE REASON: [ALERT-109286] 
GRANT SELECT ON future_event_type TO alert_viewer;
GRANT ALTER,DEBUG,DELETE,FLASHBACK,INDEX,INSERT,ON COMMIT REFRESH,QUERY REWRITE,REFERENCES,SELECT,UPDATE ON future_event_type TO inter_alert_v2;
-- CHANGE END: S�rgio Santos