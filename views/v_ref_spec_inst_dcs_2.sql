DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM user_views v
     WHERE v.view_name = 'V_REF_SPEC_INST_DCS_2';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop view v_ref_spec_inst_dcs_2';
    END IF;
END;
/