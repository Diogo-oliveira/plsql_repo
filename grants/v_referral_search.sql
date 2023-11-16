-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-JAN-06
-- CHANGED REASON: ALERT-211941
DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM dba_users u
     WHERE u.username = 'INTERFACE_P1';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE q'[grant select on V_REFERRAL_SEARCH to interface_p1]';
    END IF;
END;
/