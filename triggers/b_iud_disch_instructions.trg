CREATE OR REPLACE
TRIGGER b_iud_disch_instructions
    BEFORE DELETE OR INSERT OR UPDATE ON disch_instructions
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_disch_instructions       := 'DISCH_INSTRUCTIONS.CODE_DISCH_INSTRUCTIONS.' ||
                                              :NEW.id_disch_instructions;
        :NEW.code_disch_instructions_title := 'DISCH_INSTRUCTIONS.CODE_DISCH_INSTRUCTIONS_TITLE.' ||
                                              :NEW.id_disch_instructions;
        :NEW.adw_last_update               := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_disch_instructions
            OR code_translation = :OLD.code_disch_instructions_title;

    ELSIF updating
    THEN
        :NEW.code_disch_instructions       := 'DISCH_INSTRUCTIONS.CODE_DISCH_INSTRUCTIONS.' ||
                                              :OLD.id_disch_instructions;
        :NEW.code_disch_instructions_title := 'DISCH_INSTRUCTIONS.CODE_DISCH_INSTRUCTIONS_TITLE.' ||
                                              :OLD.id_disch_instructions;
        :NEW.adw_last_update               := SYSDATE;
    END IF;
END;
/
