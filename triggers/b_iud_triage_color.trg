CREATE OR REPLACE
TRIGGER b_iud_triage_color
    BEFORE DELETE OR INSERT OR UPDATE ON triage_color
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_color := 'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || :NEW.id_triage_color;
        :NEW.code_accuity      := 'TRIAGE_COLOR.CODE_ACCUITY.' || :NEW.id_triage_color;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_color
            OR code_translation = :OLD.code_accuity;
    ELSIF updating
    THEN
        :NEW.code_triage_color := 'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || :OLD.id_triage_color;
        :NEW.code_accuity      := 'TRIAGE_COLOR.CODE_ACCUITY.' || :OLD.id_triage_color;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
