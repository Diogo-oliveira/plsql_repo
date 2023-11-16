CREATE OR REPLACE
TRIGGER b_iud_sys_button_in
    BEFORE DELETE OR INSERT OR UPDATE ON sys_button
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_intern_name := 'SYS_BUTTON.CODE_INTERN_NAME.' || :NEW.id_sys_button;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_intern_name;
    ELSIF updating
    THEN
        :NEW.code_intern_name := 'SYS_BUTTON.CODE_INTERN_NAME.' || :OLD.id_sys_button;
    END IF;
END;
/
