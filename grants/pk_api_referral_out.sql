-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 06/12/2011 10:45
-- CHANGE REASON: [ALERT-202367] 
DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM dba_users u
     WHERE u.username = 'INTERFACE_P1';

    IF l_count > 0
    THEN
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON pk_api_referral_out TO INTERFACE_P1';
    END IF;
END;
/
-- CHANGE END: Ana Monteiro