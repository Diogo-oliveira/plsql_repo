CREATE OR REPLACE
TRIGGER b_iud_social_class
    BEFORE DELETE OR INSERT OR UPDATE ON social_class
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_social_class := 'SOCIAL_CLASS.CODE_SOCIAL_CLASS.' || :NEW.id_social_class;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_social_class;

    ELSIF updating
    THEN
        :NEW.code_social_class := 'SOCIAL_CLASS.CODE_SOCIAL_CLASS.' || :OLD.id_social_class;
        :NEW.adw_last_update   := SYSDATE;

    END IF;
END;
/
