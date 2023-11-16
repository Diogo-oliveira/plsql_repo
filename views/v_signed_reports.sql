DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -00942);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'DROP VIEW v_signed_reports';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;
END;
/

