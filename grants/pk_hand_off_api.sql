-- CHANGED BY: José Brito
-- CHANGE DATE: 10/12/2010 16:06
-- CHANGE REASON: [ALERT-148454] Grants for pk_hand_off_api
BEGIN
EXECUTE IMMEDIATE 'GRANT EXECUTE ON ALERT.PK_HAND_OFF_API TO ALERT_ADTCOD';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING: Object already exists.');
END;
/
-- CHANGE END: José Brito

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 22/03/2011 17:44
-- CHANGE REASON: [ALERT-167793] API for "Transfer Episode Responsability"
GRANT EXECUTE ON PK_HAND_OFF_API TO INTF_ALERT;
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Álvaro Vasconcelos
-- CHANGE DATE: 12/09/2011 17:44
-- CHANGE REASON: [ALERT-192303]
GRANT execute ON pk_hand_off_api TO alert_reset;
-- CHANGE END: Álvaro Vasconcelos