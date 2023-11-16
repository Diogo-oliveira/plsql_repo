-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 02/05/2011 15:30
-- CHANGE REASON: [ALERT-175818] XMAP relationship trigger
DECLARE
    l_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(l_exception, -04080); -- trigger 'B_IU_XMAP_RELATIONSHIP' does not exist
BEGIN
    EXECUTE IMMEDIATE 'drop trigger b_iu_xmap_relationship';
EXCEPTION
    WHEN l_exception THEN
        dbms_output.put_line('trigger B_IU_XMAP_RELATIONSHIP does not exist');
END;
/
-- CHANGE END: Carlos Loureiro
