-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 25/08/2010 10:41
-- CHANGE REASON: [ALERT-95691] 
GRANT SELECT ON dictation_report_hist TO alert_viewer;
GRANT ALTER,DEBUG,DELETE,FLASHBACK,INDEX,INSERT,ON COMMIT REFRESH,QUERY REWRITE,REFERENCES,SELECT,UPDATE ON dictation_report_hist TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 06-APR-2011
-- CHANGE REASON: [ALERT-171286] 
grant select, update, delete on DICTATION_REPORT_HIST to alert_reset;
-- CHANGE END: Ana Coelho
