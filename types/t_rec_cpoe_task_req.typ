-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 12/07/2010 20:27
-- CHANGE REASON: [ALERT-111270] CPOE performance fix
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303);
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_cpoe_task_req AS OBJECT (id_task_type NUMBER(24), id_request NUMBER(24))';
EXCEPTION
    WHEN e_already_exists THEN
        NULL;
END;
/
-- CHANGE END: Carlos Loureiro

-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 12/10/2010
-- CHANGE REASON: [ALERT-128777] CPOE improvement
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303);
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_cpoe_task_req AS OBJECT (id_task_type NUMBER(24), id_request NUMBER(24), flg_status VARCHAR2(10 CHAR))';
EXCEPTION
    WHEN e_already_exists THEN
        NULL;
END;
/
-- CHANGE END: Tiago Silva