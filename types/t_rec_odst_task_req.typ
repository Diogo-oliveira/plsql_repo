-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 10/11/2011 10:00
-- CHANGE REASON: [ALERT-118679] Institutionalized Diets integration in Order Sets
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303); -- cannot drop or replace a type with type or table dependents
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_odst_task_req AS OBJECT
(
  order_set_task  NUMBER(24),
  task_type       NUMBER(24),
  task_request    NUMBER(24)
)';
EXCEPTION
    WHEN e_already_exists THEN
        dbms_output.put_line('type t_rec_odst_task_req already exists');
END;
/
-- CHANGE END: Carlos Loureiro
