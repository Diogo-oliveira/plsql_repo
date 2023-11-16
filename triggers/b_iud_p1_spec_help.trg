CREATE OR REPLACE
TRIGGER b_iud_p1_spec_help
    BEFORE DELETE OR INSERT OR UPDATE ON p1_spec_help
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_title := 'P1_SPEC_HELP.CODE_TITLE.' || :NEW.id_spec_help;
        :NEW.code_text  := 'P1_SPEC_HELP.CODE_TEXT.' || :NEW.id_spec_help;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_title
            OR code_translation = :OLD.code_text;
    ELSIF updating
    THEN
        :NEW.code_title      := 'P1_SPEC_HELP.CODE_TITLE.' || :OLD.id_spec_help;
        :NEW.code_text       := 'P1_SPEC_HELP.CODE_TEXT.' || :OLD.id_spec_help;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
