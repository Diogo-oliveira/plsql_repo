-- CHANGED BY: José Brito
-- CHANGE DATE: 18/11/2010 14:16
-- CHANGE REASON: [ALERT-142370] Hand-off NL refactoring - replication to 2.6.0.4
BEGIN
    EXECUTE IMMEDIATE 'GRANT SELECT ON ALERT.EPIS_MULTI_PROFRESP_HIST TO ALERT_VIEWER';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING: Object already exists.');
END;
/
-- CHANGE END: José Brito