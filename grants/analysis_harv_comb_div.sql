-- ADDED BY: Jose Castro
-- ADDED DATE: 17/02/2011
-- ADDED REASON: ALERT-842
-- Grant/Revoke object privileges 
grant select on ANALYSIS_HARV_COMB_DIV to ALERT_VIEWER;

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ANALYSIS_HARV_COMB_DIV to alert_reset;
-- CHANGE END: Ana Coelho