DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM user_objects o
     WHERE o.object_type = 'TRIGGER'
       AND o.object_name = 'B_U_P1_EXTERNAL_REQUEST';

    IF l_count = 1
    THEN
        EXECUTE IMMEDIATE 'drop trigger b_u_p1_external_request';
    END IF;
END;
/
