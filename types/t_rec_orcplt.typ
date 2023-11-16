-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 19/04/2011 20:00
-- CHANGE REASON: [ALERT-173229] Order recurrence 
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303); -- cannot drop or replace a type with type or table dependents
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_orcplt AS OBJECT
    (
      id_order_recurr_plan_time     NUMBER(24),
      id_order_recurr_plan          NUMBER(24),
      id_order_recurr_option_parent NUMBER(24),
      id_order_recurr_option_child  NUMBER(24),
      exec_time                     INTERVAL DAY(0) TO SECOND(0),
      exec_time_offset              NUMBER(6),
      id_unit_meas_exec_time_offset NUMBER(24)
    )';
EXCEPTION
    WHEN e_already_exists THEN
        dbms_output.put_line('type t_rec_orcplt already exists');
END;
/
-- CHANGE END: Carlos Loureiro

