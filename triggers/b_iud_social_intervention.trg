CREATE OR REPLACE
TRIGGER b_iud_social_intervention
    BEFORE DELETE OR INSERT OR UPDATE ON social_intervention
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_social_intervention := 'SOCIAL_INTERVENTION.CODE_SOCIAL_INTERVENTION.' || :NEW.id_social_intervention;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_social_intervention;

    ELSIF updating
    THEN
        :NEW.code_social_intervention := 'SOCIAL_INTERVENTION.CODE_SOCIAL_INTERVENTION.' || :OLD.id_social_intervention;
        :NEW.adw_last_update          := SYSDATE;

    END IF;
END;
/
