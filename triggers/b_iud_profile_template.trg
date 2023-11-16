CREATE OR REPLACE
TRIGGER b_iud_profile_template
    BEFORE DELETE OR INSERT OR UPDATE ON profile_template
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_profile_template := 'PROFILE_TEMPLATE.CODE_PROFILE_TEMPLATE.' || :NEW.id_profile_template;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_profile_template;
    ELSIF updating
    THEN
        :NEW.code_profile_template := 'PROFILE_TEMPLATE.CODE_PROFILE_TEMPLATE.' || :OLD.id_profile_template;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
