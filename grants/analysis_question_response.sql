GRANT SELECT ON ANALYSIS_QUESTION_RESPONSE TO INTER_ALERT_V2;

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.ANALYSIS_QUESTION_RESPONSE to alert_reset;
-- CHANGE END: Ana Coelho