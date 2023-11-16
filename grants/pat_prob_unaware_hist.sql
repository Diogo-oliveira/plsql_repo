-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 06/04/2011 11:42
-- CHANGE REASON: [ALERT-159066] 
GRANT SELECT ON pat_prob_unaware_hist TO alert_viewer;
GRANT ALTER,DEBUG,DELETE,FLASHBACK,INDEX,INSERT,ON COMMIT REFRESH,QUERY REWRITE,REFERENCES,SELECT,UPDATE ON pat_prob_unaware_hist TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 26-APR-2011
-- CHANGE REASON: [ALERT-174719]
grant select, update, delete on ALERT.pat_prob_unaware_hist to alert_reset;
-- CHANGE END: Ana Coelho