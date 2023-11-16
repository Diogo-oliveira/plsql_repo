CREATE OR REPLACE
TRIGGER b_iud_triage_board
    BEFORE DELETE OR INSERT OR UPDATE ON triage_board
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_board      := 'TRIAGE_BOARD.CODE_TRIAGE_BOARD.' || :NEW.id_triage_board;
        :NEW.code_help_triage_board := 'TRIAGE_BOARD.CODE_HELP_TRIAGE_BOARD.' || :NEW.id_triage_board;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_board
            OR code_translation = :OLD.code_help_triage_board;
    ELSIF updating
    THEN
        :NEW.code_triage_board      := 'TRIAGE_BOARD.CODE_TRIAGE_BOARD.' || :OLD.id_triage_board;
        :NEW.code_help_triage_board := 'TRIAGE_BOARD.CODE_HELP_TRIAGE_BOARD.' || :OLD.id_triage_board;
        :NEW.adw_last_update        := SYSDATE;
    END IF;
END;
/
