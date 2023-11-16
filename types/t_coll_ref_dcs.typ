DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM user_types u
     WHERE u.type_name = 'T_COLL_REF_DCS';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop type t_coll_ref_dcs';
    END IF;
END;
/