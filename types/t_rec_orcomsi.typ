-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 20/04/2011 10:00
-- CHANGE REASON: [ALERT-173229] Order recurrence 
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303); -- cannot drop or replace a type with type or table dependents
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_orcomsi AS OBJECT
    (
        id_order_recurr_option     NUMBER(24),
		id_order_recurr_area       NUMBER(24),
        rank                       NUMBER(6),
		flg_default                VARCHAR2(1 CHAR)
    )';
EXCEPTION
    WHEN e_already_exists THEN
        dbms_output.put_line('type t_rec_orcomsi already exists');
END;
/
-- CHANGE END: Tiago Silva
