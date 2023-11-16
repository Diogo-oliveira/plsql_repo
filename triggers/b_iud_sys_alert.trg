CREATE OR REPLACE
TRIGGER b_iud_sys_alert
    BEFORE DELETE OR INSERT OR UPDATE ON sys_alert
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_alert := 'SYS_ALERT.CODE_ALERT.' || :NEW.id_sys_alert;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_alert;
    ELSIF updating
    THEN
        :NEW.code_alert := 'SYS_ALERT.CODE_ALERT.' || :OLD.id_sys_alert;
    END IF;
END;
/
