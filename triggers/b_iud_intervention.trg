CREATE OR REPLACE
TRIGGER b_iud_intervention
    BEFORE DELETE OR INSERT OR UPDATE ON intervention
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_intervention := 'INTERVENTION.CODE_INTERVENTION.' || :NEW.id_intervention;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_intervention;
    ELSIF updating
    THEN
        :NEW.code_intervention := 'INTERVENTION.CODE_INTERVENTION.' || :OLD.id_intervention;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
