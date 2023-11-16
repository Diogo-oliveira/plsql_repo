-- ADDED BY: Jose Castro
-- ADDED DATE: 13/10/2010
-- ADDED REASON: ALERT-29500
-- Grant/Revoke object privileges 
grant select on EXAM_TIME_OUT to ALERT_VIEWER;
-- ADDED END

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.EXAM_TIME_OUT to alert_reset;
-- CHANGE END: Ana Coelho