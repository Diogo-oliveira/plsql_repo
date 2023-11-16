CREATE OR REPLACE
TRIGGER b_iud_triage_units
    BEFORE DELETE OR INSERT OR UPDATE ON triage_units
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_units := 'TRIAGE_UNITS.CODE_TRIAGE_UNITS.' || :NEW.id_triage_units;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_units;
    ELSIF updating
    THEN
        :NEW.code_triage_units := 'TRIAGE_UNITS.CODE_TRIAGE_UNITS.' || :OLD.id_triage_units;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
