CREATE OR REPLACE
TRIGGER b_iud_triage_disc_help
    BEFORE DELETE OR INSERT OR UPDATE ON triage_disc_help
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_disc_help       := 'TRIAGE_DISC_HELP.CODE_TRIAGE_DISC_HELP.' || :NEW.id_triage_disc_help;
        :NEW.code_title_triage_disc_help := 'TRIAGE_DISC_HELP.CODE_TITLE_TRIAGE_DISC_HELP.' || :NEW.id_triage_disc_help;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_disc_help
            OR code_translation = :OLD.code_title_triage_disc_help;
    ELSIF updating
    THEN
        :NEW.code_triage_disc_help       := 'TRIAGE_DISC_HELP.CODE_TRIAGE_DISC_HELP.' || :OLD.id_triage_disc_help;
        :NEW.code_title_triage_disc_help := 'TRIAGE_DISC_HELP.CODE_TITLE_TRIAGE_DISC_HELP.' || :OLD.id_triage_disc_help;
    END IF;
END;
/
