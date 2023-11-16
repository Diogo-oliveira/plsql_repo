CREATE OR REPLACE
TRIGGER b_iud_vaccine
    BEFORE DELETE OR INSERT OR UPDATE ON vaccine
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_vaccine := 'VACCINE.CODE_VACCINE.' || :NEW.id_vaccine;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_vaccine;
    ELSIF updating
    THEN
        :NEW.code_vaccine    := 'VACCINE.CODE_VACCINE.' || :OLD.id_vaccine;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
