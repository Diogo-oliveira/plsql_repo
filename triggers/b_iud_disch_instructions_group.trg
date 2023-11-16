CREATE OR REPLACE
TRIGGER b_iud_disch_instructions_group
    BEFORE DELETE OR INSERT OR UPDATE ON disch_instructions_group
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_disch_instructions_group := 'DISCH_INSTRUCTIONS_GROUP.CODE_DISCH_INSTRUCTIONS_GROUP.' ||
                                              :NEW.id_disch_instructions_group;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_disch_instructions_group;
    ELSIF updating
    THEN
        :NEW.code_disch_instructions_group := 'DISCH_INSTRUCTIONS_GROUP.CODE_DISCH_INSTRUCTIONS_GROUP.' ||
                                              :OLD.id_disch_instructions_group;
        :NEW.adw_last_update               := SYSDATE;
    END IF;
END;
/
