-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 26/07/2011 15:01
-- CHANGE REASON: [ALERT-188174] 
GRANT DELETE,SELECT,UPDATE ON pat_child_feed_dev_hist TO alert_reset;
GRANT SELECT ON pat_child_feed_dev_hist TO alert_viewer;
GRANT ALTER,DEBUG,DELETE,FLASHBACK,INDEX,INSERT,ON COMMIT REFRESH,QUERY REWRITE,REFERENCES,SELECT,UPDATE ON pat_child_feed_dev_hist TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira