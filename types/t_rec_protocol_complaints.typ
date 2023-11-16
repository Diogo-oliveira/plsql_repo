-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 30/11/2010 17:30
-- CHANGE REASON: [ALERT-149189] Chief complaints filter for Guidelines, Protocols and Order Sets
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303);
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_protocol_complaints AS OBJECT (id_complaint NUMBER(24), desc_complaint VARCHAR2(4000))';
EXCEPTION
    WHEN e_already_exists THEN
        NULL;
END;
/
-- CHANGE END: Carlos Loureiro