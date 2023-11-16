-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/12/2013 09:32
-- CHANGE REASON: [ALERT-270040] 
grant DELETE, INSERT,
    SELECT , UPDATE ON vs_attribute_soft_inst TO alert_config;
grant
    SELECT ON vs_attribute_soft_inst TO alert_viewer;
grant ALTER, debug, DELETE, flashback, INDEX, INSERT, ON COMMIT refresh, query rewrite, references,
    SELECT , UPDATE ON vs_attribute_soft_inst TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira