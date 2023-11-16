CREATE OR REPLACE
TRIGGER b_iud_external_cause
    BEFORE DELETE OR INSERT OR UPDATE ON external_cause
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_external_cause := 'EXTERNAL_CAUSE.CODE_EXTERNAL_CAUSE.' || :NEW.id_external_cause;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_external_cause;
    ELSIF updating
    THEN
        :NEW.code_external_cause := 'EXTERNAL_CAUSE.CODE_EXTERNAL_CAUSE.' || :OLD.id_external_cause;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
