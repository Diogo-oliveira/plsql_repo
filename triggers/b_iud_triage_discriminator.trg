CREATE OR REPLACE
TRIGGER b_iud_triage_discriminator
    BEFORE DELETE OR INSERT OR UPDATE ON triage_discriminator
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_discriminator := 'TRIAGE_DISCRIMINATOR.CODE_TRIAGE_DISCRIMINATOR.' ||
                                          :NEW.id_triage_discriminator;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_discriminator;
    ELSIF updating
    THEN
        :NEW.code_triage_discriminator := 'TRIAGE_DISCRIMINATOR.CODE_TRIAGE_DISCRIMINATOR.' ||
                                          :OLD.id_triage_discriminator;
        :NEW.adw_last_update           := SYSDATE;
    END IF;
END;
/
