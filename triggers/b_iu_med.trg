DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04080);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'DROP TRIGGER B_IU_MED';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;
END;
/
/
