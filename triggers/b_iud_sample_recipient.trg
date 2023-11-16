CREATE OR REPLACE
TRIGGER b_iud_sample_recipient
    BEFORE DELETE OR INSERT OR UPDATE ON sample_recipient
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sample_recipient := 'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || :NEW.id_sample_recipient;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sample_recipient;
    ELSIF updating
    THEN
        :NEW.code_sample_recipient := 'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || :OLD.id_sample_recipient;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
