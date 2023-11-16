CREATE OR REPLACE
TRIGGER b_iud_prep_message
    BEFORE DELETE OR INSERT OR UPDATE ON prep_message
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_prep_message := 'PREP_MESSAGE.CODE_PREP_MESSAGE.' || :NEW.id_prep_message;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_prep_message;
    ELSIF updating
    THEN
        :NEW.code_prep_message := 'PREP_MESSAGE.CODE_PREP_MESSAGE.' || :OLD.id_prep_message;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
