-- CHANGED BY: Joana Barroso
-- CHANGE DATE: 05/07/2012 17:54
-- CHANGE REASON: [ALERT-235411 ] 
DECLARE
    l_var PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_var
      FROM dba_users
     WHERE username = 'ADW_STG';
    IF l_var > 0
    THEN
        EXECUTE IMMEDIATE 'grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG';
        dbms_output.put_line('grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG');
    END IF;
END;
/

DECLARE
    l_var PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_var
      FROM dba_users
     WHERE username = 'ADW_STG_PCK';
    IF l_var > 0
    THEN
        EXECUTE IMMEDIATE 'grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG_PCK';
        dbms_output.put_line('grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG_PCK');
    END IF;
END;
/

DECLARE
    l_var PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_var
      FROM dba_users
     WHERE username = 'ADW_STG_PFH';
    IF l_var > 0
    THEN
        EXECUTE IMMEDIATE 'grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG_PFH';
        dbms_output.put_line('grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG_PFH');
    END IF;
END;
/

DECLARE
    l_var PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_var
      FROM dba_users
     WHERE username = 'ADW_STG_P1';
    IF l_var > 0
    THEN
        EXECUTE IMMEDIATE 'grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG_P1';
        dbms_output.put_line('grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_STG_P1');
    END IF;
END;
/

DECLARE
    l_var PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_var
      FROM dba_users
     WHERE username = 'ADW_SVN';
    IF l_var > 0
    THEN
        EXECUTE IMMEDIATE 'grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_SVN';
        dbms_output.put_line('grant select on V_PRINTED_MCDT_PRESCRIPTION to ADW_SVN');
    END IF;
END;
/
-- CHANGE END: Joana Barroso