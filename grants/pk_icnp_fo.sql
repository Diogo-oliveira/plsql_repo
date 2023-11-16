-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 17/12/2010 16:06
-- CHANGE REASON: [ALERT-150268] 
GRANT EXECUTE ON ALERT.PK_ICNP_FO TO ALERT_VIEWER;
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Luis Oliveira
-- CHANGE DATE: 29/07/2011 18:01
-- CHANGE REASON: [ALERT-182932] Implementation of the recurrence mechanism in ICNP functionality
DECLARE
    e_grant_not_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_grant_not_exists, -01927); -- cannot revoke privileges you did not grant
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'revoke execute on pk_icnp_fo from alert_viewer';
  EXCEPTION
    WHEN e_grant_not_exists THEN
      dbms_output.put_line('There is no grant for pk_icnp_fo from alert_viewer');   
  END;
  BEGIN
    EXECUTE IMMEDIATE 'revoke execute on pk_icnp_fo from alert_reports';
  EXCEPTION
    WHEN e_grant_not_exists THEN
      dbms_output.put_line('There is no grant for pk_icnp_fo from alert_reports');   
  END;    
END;
/  
-- CHANGE END: Luis Oliveira