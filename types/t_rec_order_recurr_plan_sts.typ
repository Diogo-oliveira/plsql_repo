-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 10/05/2011 15:00
-- CHANGE REASON: [ALERT-177619] Order recurrence job enabling
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303); -- cannot drop or replace a type with type or table dependents
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_order_recurr_plan_sts AS OBJECT
    (
      id_order_recurrence_plan NUMBER(24),
      flg_status               VARCHAR2(1 CHAR)
    )';
EXCEPTION
    WHEN e_already_exists THEN
        dbms_output.put_line('type t_rec_order_recurr_plan_sts already exists');
END;
/
-- CHANGE END: Ana Monteiro
