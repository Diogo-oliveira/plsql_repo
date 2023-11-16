-- CHANGED BY: José Brito
-- CHANGE DATE: 28/10/2009 19:29
-- CHANGE REASON: [ALERT-52603] Taking responsibility over episode by multiple professionals
GRANT SELECT ON ALERT.EPIS_MULTI_PROF_RESP TO ALERT_VIEWER;
-- CHANGE END: José Brito

-- CHANGED BY: José Brito
-- CHANGE DATE: 10/12/2010 16:06
-- CHANGE REASON: [ALERT-148454] Grants for pk_hand_off_api
BEGIN
EXECUTE IMMEDIATE 'GRANT SELECT ON ALERT.EPIS_MULTI_PROF_RESP TO ALERT_ADTCOD';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING: Object already exists.');
END;
/
-- CHANGE END: José Brito