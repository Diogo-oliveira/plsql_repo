CREATE OR REPLACE
TRIGGER b_iud_sys_functionality
    BEFORE DELETE OR INSERT OR UPDATE ON sys_functionality
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_functionality := 'SYS_FUNCTIONALITY.CODE_FUNCTIONALITY.' || :NEW.id_functionality;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_functionality;
    ELSIF updating
    THEN
        :NEW.code_functionality := 'SYS_FUNCTIONALITY.CODE_FUNCTIONALITY.' || :OLD.id_functionality;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
