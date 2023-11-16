CREATE OR REPLACE
TRIGGER b_iud_advanced_input_field
    BEFORE DELETE OR INSERT OR UPDATE ON advanced_input_field
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_advanced_input_field := 'ADVANCED_INPUT_FIELD.CODE_ADVANCED_INPUT_FIELD.' ||
                                          :NEW.id_advanced_input_field;
        :NEW.adw_last_update           := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_advanced_input_field;
    ELSIF updating
    THEN
        :NEW.code_advanced_input_field := 'ADVANCED_INPUT_FIELD.CODE_ADVANCED_INPUT_FIELD.' ||
                                          :OLD.id_advanced_input_field;
        :NEW.adw_last_update           := SYSDATE;
    END IF;
END;
/
