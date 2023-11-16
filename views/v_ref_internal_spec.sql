-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-JUL-23
-- CHANGED REASON: ALERT-237078
DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM user_views v
     WHERE v.view_name = 'V_REF_INTERNAL_SPEC';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'drop view v_ref_internal_spec';
    END IF;
END;
/
-- CHANGE END: Ana Monteiro
