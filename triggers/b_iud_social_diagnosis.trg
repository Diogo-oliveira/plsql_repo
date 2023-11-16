CREATE OR REPLACE
TRIGGER b_iud_social_diagnosis
    BEFORE DELETE OR INSERT OR UPDATE ON social_diagnosis
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_social_diagnosis := 'SOCIAL_DIAGNOSIS.CODE_SOCIAL_DIAGNOSIS.' || :NEW.id_social_diagnosis;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_social_diagnosis;

    ELSIF updating
    THEN
        :NEW.code_social_diagnosis := 'SOCIAL_DIAGNOSIS.CODE_SOCIAL_DIAGNOSIS.' || :OLD.id_social_diagnosis;
        :NEW.adw_last_update       := SYSDATE;

    END IF;
END;
/
