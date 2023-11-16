DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -04080);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'DROP TRIGGER a_iud_drug_req_supply';
    EXCEPTION
        WHEN e_object_exists THEN
            NULL;
    END;
END;
/

