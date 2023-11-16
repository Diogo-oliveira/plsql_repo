CREATE OR REPLACE
TRIGGER b_iu_sr_intervention
    BEFORE INSERT OR UPDATE OF id_sr_intervention ON sr_intervention
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_intervention := 'SR_INTERVENTION.CODE_SR_INTERVENTION.' || :NEW.id_sr_intervention;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_intervention;
    ELSIF updating
    THEN
        :NEW.code_sr_intervention := 'SR_INTERVENTION.CODE_SR_INTERVENTION.' || :OLD.id_sr_intervention;
        :NEW.adw_last_update      := SYSDATE;
    END IF;
END;
/
