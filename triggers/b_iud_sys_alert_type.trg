CREATE OR REPLACE
TRIGGER b_iud_sys_alert_type
    BEFORE DELETE OR INSERT OR UPDATE ON alert.sys_alert_type
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sys_alert_type := 'SYS_ALERT_TYPE.CODE_SYS_ALERT_TYPE.' || :NEW.id_sys_alert_type;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sys_alert_type;
    ELSIF updating
    THEN
        :NEW.code_sys_alert_type := 'SYS_ALERT_TYPE.CODE_SYS_ALERT_TYPE.' || :OLD.id_sys_alert_type;
    END IF;
    :NEW.adw_last_update := SYSDATE;
END;
/
