grant select on epis_pn_det_hist to ALERT_VIEWER; 

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-ABR-2011
-- CHANGE REASON: [ALERT-171286] 
DECLARE
log_error EXCEPTION;
PRAGMA EXCEPTION_INIT(log_error, -01927);
BEGIN
  EXECUTE IMMEDIATE 'grant select, update, delete on ALERT.EPIS_PN_DET_HIST to alert_reset';
EXCEPTION
WHEN log_error THEN
dbms_output.put_line('Nothing done.');
END;
/
-- CHANGE END: [ALERT-171286] 