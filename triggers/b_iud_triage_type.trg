CREATE OR REPLACE
TRIGGER b_iud_triage_type
    BEFORE DELETE OR INSERT OR UPDATE ON triage_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_type := 'TRIAGE_TYPE.CODE_TRIAGE_TYPE.' || :NEW.id_triage_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_type;
    ELSIF updating
    THEN
        :NEW.code_triage_type := 'TRIAGE_TYPE.CODE_TRIAGE_TYPE.' || :OLD.id_triage_type;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
