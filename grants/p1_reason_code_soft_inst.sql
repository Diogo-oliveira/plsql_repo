-- CHANGED BY: Joana Barroso
-- CHANGE DATE: 23/03/2012 10:45
-- CHANGE REASON: [ALERT-224618] 
GRANT SELECT ON p1_reason_code_soft_inst TO ALERT_VIEWER;
GRANT SELECT ON p1_reason_code_soft_inst TO ALERT_INTER;
GRANT SELECT, INSERT, UPDATE, DELETE ON p1_reason_code_soft_inst TO ALERT_CONFIG;
-- CHANGE END: Joana Barroso