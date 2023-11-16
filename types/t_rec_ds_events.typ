-- CHANGED BY: José Silva
-- CHANGE DATE: 03/05/2012 18:22
-- CHANGE REASON: [ALERT-228955] EST simplified triage
DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_table_ds_events'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/

CREATE OR REPLACE TYPE t_rec_ds_events AS OBJECT
(
    id_ds_event        NUMBER(24),
    origin             NUMBER(24),
    value              VARCHAR2(200 CHAR),
    target             NUMBER(24),
    flg_event_type     VARCHAR2(1 CHAR)
);
/

CREATE OR REPLACE TYPE t_table_ds_events IS TABLE OF t_rec_ds_events;
/
-- CHANGE END: José Silva