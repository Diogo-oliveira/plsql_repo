DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM user_objects o
     WHERE o.object_type = 'TRIGGER'
       AND o.object_name = 'A_I_REF_UPDATE_EVENT';

    IF l_count = 1
    THEN
        EXECUTE IMMEDIATE 'drop trigger a_i_ref_update_event';
    END IF;
END;
/