grant select on waiting_list to ALERT_VIEWER;

-- CHANGED BY: Tiago Goncalves
-- CHANGE DATE: 16/09/2019
-- CHANGE REASON: [INTERALERT-3894] Admission and Surgery waiting list > error is displayed and no requests are returned
grant select on waiting_list to alert_inter;
-- CHANGE END: Tiago Goncalves