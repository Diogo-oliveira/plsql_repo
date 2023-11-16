CREATE OR REPLACE
TRIGGER b_iud_triage_board_group
    BEFORE DELETE OR INSERT OR UPDATE ON triage_board_group
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_board_group      := 'TRIAGE_BOARD_GROUP.CODE_TRIAGE_BOARD_GROUP.' ||
                                             :NEW.id_triage_board_group;
        :NEW.code_help_triage_board_group := 'TRIAGE_BOARD_GROUP.CODE_HELP_TRIAGE_BOARD_GROUP.' ||
                                             :NEW.id_triage_board_group;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_board_group
            OR code_translation = :OLD.code_help_triage_board_group;
    ELSIF updating
    THEN
        :NEW.code_triage_board_group      := 'TRIAGE_BOARD_GROUP.CODE_TRIAGE_BOARD_GROUP.' ||
                                             :OLD.id_triage_board_group;
        :NEW.code_help_triage_board_group := 'TRIAGE_BOARD_GROUP.CODE_HELP_TRIAGE_BOARD_GROUP.' ||
                                             :OLD.id_triage_board_group;
        :NEW.adw_last_update              := SYSDATE;
    END IF;
END;
/
