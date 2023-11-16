CREATE OR REPLACE
TRIGGER b_iud_system_apparati
    BEFORE DELETE OR INSERT OR UPDATE ON system_apparati
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_system_apparati := 'SYSTEM_APPARATI.CODE_SYSTEM_APPARATI.' || :NEW.id_system_apparati;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_system_apparati;

    ELSIF updating
    THEN
        :NEW.code_system_apparati := 'SYSTEM_APPARATI.CODE_SYSTEM_APPARATI.' || :OLD.id_system_apparati;
        :NEW.adw_last_update      := SYSDATE;

    END IF;
END;
/
