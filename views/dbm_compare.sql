DECLARE
    e_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_not_exist, -00942);
BEGIN
    EXECUTE IMMEDIATE 'DROP view DBM_COMPARE';
EXCEPTION
    WHEN e_not_exist THEN
        NULL;
END;
/
