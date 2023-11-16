-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 06/04/2011 11:41
-- CHANGE REASON: [ALERT-159066] 
GRANT EXECUTE ON pk_problems_ux TO alert_reports;
GRANT EXECUTE ON pk_problems_ux TO alert_viewer;
GRANT DEBUG,EXECUTE ON pk_problems_ux TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira