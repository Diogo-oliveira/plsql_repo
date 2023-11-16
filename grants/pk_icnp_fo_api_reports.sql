-- CHANGED BY: Luis Oliveira
-- CHANGE DATE: 29/07/2011 18:01
-- CHANGE REASON: [ALERT-182932] Implementation of the recurrence mechanism in ICNP functionality
grant execute on pk_icnp_fo_api_reports to alert_reports;
-- CHANGE END: Luis Oliveira

-- CHANGED BY: Luis Oliveira
-- CHANGE DATE: 19/08/2011 17:56
-- CHANGE REASON: [ALERT-191798] Implementation of the recurrence mechanism in ICNP functionality
DECLARE
  e_grant_not_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_grant_not_exists, -01927); -- cannot revoke privileges you did not grant
BEGIN
  EXECUTE IMMEDIATE 'revoke execute on pk_icnp_fo_api_reports from alert_reports';
EXCEPTION
  WHEN e_grant_not_exists THEN
    dbms_output.put_line('There is no grant for pk_icnp_fo_api_reports from alert_reports');   
END;
/
grant execute on pk_icnp_fo_api_reports to alert_viewer;
-- CHANGE END: Luis Oliveira