CREATE OR REPLACE
TRIGGER b_iud_triage_nurse
    BEFORE DELETE OR INSERT OR UPDATE ON triage_nurse
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_nurse := 'TRIAGE_NURSE.CODE_TRIAGE_NURSE.' || :NEW.id_triage_nurse;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_nurse;
    ELSIF updating
    THEN
        :NEW.code_triage_nurse := 'TRIAGE_NURSE.CODE_TRIAGE_NURSE.' || :OLD.id_triage_nurse;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
