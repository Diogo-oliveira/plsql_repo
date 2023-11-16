-- CHANGED BY: José Brito
-- CHANGE DATE: 09/04/2010 11:15
-- CHANGE REASON: [ALERT-87635] Manchester triage improvements - replication in 2.6
BEGIN
   EXECUTE IMMEDIATE 'GRANT SELECT ON ALERT.TRIAGE_AGE_LIMIT TO ALERT_VIEWER';
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line('WARNING: Object already exists.');
END;
/
-- CHANGE END: José Brito