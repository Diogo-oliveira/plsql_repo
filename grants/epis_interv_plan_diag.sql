-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 22/09/2011 09:39
-- CHANGE REASON: [ALERT-194825] 
GRANT SELECT ON epis_interv_plan_diag TO alert_viewer;
GRANT ALTER,DEBUG,DELETE,FLASHBACK,INDEX,INSERT,ON COMMIT REFRESH,QUERY REWRITE,REFERENCES,SELECT,UPDATE ON epis_interv_plan_diag TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira