-- CHANGED BY: João Martins
-- CHANGE DATE: 11/12/2009 21:07
-- CHANGE REASON: [ALERT-62132] CPOE Procedures/Dressings/Patient education
GRANT EXECUTE ON ALERT.PK_ICNP_CPOE TO ALERT_VIEWER;
-- CHANGE END: João Martins

-- CHANGED BY: Luis Oliveira
-- CHANGE DATE: 29/07/2011 18:01
-- CHANGE REASON: [ALERT-182932] Implementation of the recurrence mechanism in ICNP functionality
DECLARE
    e_grant_not_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_grant_not_exists, -01927); -- cannot revoke privileges you did not grant
BEGIN
  EXECUTE IMMEDIATE 'revoke execute on pk_icnp_cpoe from dsv';
EXCEPTION
  WHEN e_grant_not_exists THEN
    dbms_output.put_line('There is no grant for pk_icnp_cpoe from dsv');   
END;
/
-- CHANGE END: Luis Oliveira

-- CHANGED BY: Luis Oliveira
-- CHANGE DATE: 19/08/2011 17:56
-- CHANGE REASON: [ALERT-191798] Implementation of the recurrence mechanism in ICNP functionality
DECLARE
  e_grant_not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_grant_not_exists, -01927); -- cannot revoke privileges you did not grant
BEGIN
  EXECUTE IMMEDIATE 'revoke execute on pk_icnp_cpoe from alert_viewer';
EXCEPTION
  WHEN e_grant_not_exists THEN
    dbms_output.put_line('There is no grant for pk_icnp_cpoe from alert_viewer');   
END;
/
-- CHANGE END: Luis Oliveira