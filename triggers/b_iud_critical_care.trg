CREATE OR REPLACE
TRIGGER b_iud_critical_care
    BEFORE DELETE OR INSERT OR UPDATE ON critical_care
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_critical_care := 'CRITICAL_CARE.CODE_CRITICAL_CARE.' || :NEW.id_critical_care;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_critical_care;
    ELSIF updating
    THEN
        :NEW.code_critical_care := 'CRITICAL_CARE.CODE_CRITICAL_CARE.' || :OLD.id_critical_care;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
