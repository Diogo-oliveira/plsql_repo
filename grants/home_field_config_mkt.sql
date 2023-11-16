-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 22/09/2011 09:03
-- CHANGE REASON: [ALERT-192572] 
grant
    SELECT ON home_field_config_mkt TO alert_viewer;
grant ALTER, debug, DELETE, flashback, INDEX, INSERT, ON COMMIT refresh, query rewrite, references,
    SELECT , UPDATE ON home_field_config_mkt TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira