-- CHANGED BY: Jorge Silva
-- CHANGE DATE: 14/08/2014
-- CHANGE REASON: [ALERT-292603] dev db - Scheduler: missing professional chosen in requisition
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_adm_future_event AS TABLE OF t_rec_adm_future_event';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/