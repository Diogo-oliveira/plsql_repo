grant all on table_varchar to alert_viewer;
GRANT EXECUTE ON TABLE_VARCHAR TO INTF_ALERT;

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 21/06/2010 17:57
-- CHANGE REASON: [ALERT-103305] FERTIS (2.6.0.3)
grant execute on table_varchar  to intf_alert;
-- CHANGE END: Ana Monteiro


-- CHANGED BY: Vitor Oliveira
-- CHANGE DATE: 25/08/2011 
-- CHANGE REASON:ALERT-190583
grant execute on table_varchar  to alert_default;
-- CHANGE END: Vitor Oliveira