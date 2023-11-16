-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 07-APR-2011
-- CHANGE REASON: [ALERT-171286] 
DECLARE
log_error EXCEPTION;
PRAGMA EXCEPTION_INIT(log_error, -01927);
BEGIN
  EXECUTE IMMEDIATE 'grant select, update, delete on ALERT.REHAB_EPIS_PLAN_AREA to alert_reset';
EXCEPTION
WHEN log_error THEN
dbms_output.put_line('Nothing done.');
END;
/
-- CHANGED END: Ana Coelho