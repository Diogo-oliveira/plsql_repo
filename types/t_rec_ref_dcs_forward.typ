DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM user_types u
     WHERE u.type_name = 'T_REC_REF_DCS_FORWARD';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop type t_rec_ref_dcs_forward';
    END IF;
END;
/