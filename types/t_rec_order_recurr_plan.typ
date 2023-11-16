-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 19/04/2011 20:00
-- CHANGE REASON: [ALERT-173229] Order recurrence 
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303); -- cannot drop or replace a type with type or table dependents
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_order_recurr_plan AS OBJECT
    (
        id_order_recurrence_plan NUMBER(24),
        exec_number              NUMBER(6),
        exec_timestamp           TIMESTAMP(6) WITH LOCAL TIME ZONE
    )';
EXCEPTION
    WHEN e_already_exists THEN
        dbms_output.put_line('type t_rec_order_recurr_plan already exists');
END;
/
-- CHANGE END: Carlos Loureiro
