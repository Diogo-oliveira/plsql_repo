grant select on lab_tests_ea         to alert_viewer;


-- CHANGED BY: Ana Matos
-- CHANGE DATE: 16/02/2011 15:03
-- CHANGE REASON: [ALERT-41171] 
grant select, update, delete on lab_tests_ea to alert_reset;
grant select on lab_tests_ea to alert_viewer;
-- CHANGE END: Ana Matos