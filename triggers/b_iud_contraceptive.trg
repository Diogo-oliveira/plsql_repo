CREATE OR REPLACE
TRIGGER b_iud_contraceptive
    BEFORE DELETE OR INSERT OR UPDATE ON contraceptive
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_contraceptive := 'CONTRACEPTIVE.CODE_CONTRACEPTIVE.' || :NEW.id_contraceptive;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_contraceptive;
    ELSIF updating
    THEN
        :NEW.code_contraceptive := 'CONTRACEPTIVE.CODE_CONTRACEPTIVE.' || :OLD.id_contraceptive;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
