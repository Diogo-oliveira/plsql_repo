CREATE OR REPLACE
TRIGGER b_iud_triage_white_reason
    BEFORE DELETE OR INSERT OR UPDATE ON triage_white_reason
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_white_reason := 'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' || :NEW.id_triage_white_reason;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_white_reason;
    ELSIF updating
    THEN
        :NEW.code_triage_white_reason := 'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' || :OLD.id_triage_white_reason;
        :NEW.adw_last_update          := SYSDATE;
    END IF;
END;
/
