CREATE OR REPLACE
TRIGGER b_iud_vacc
    BEFORE DELETE OR INSERT OR UPDATE ON vacc
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_vacc      := 'VACC.CODE_VACC.' || :NEW.id_vacc;
        :NEW.code_desc_vacc := 'VACC.CODE_DESC_VACC.' || :NEW.id_vacc;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_vacc
            OR code_translation = :OLD.code_desc_vacc;
    ELSIF updating
    THEN
        :NEW.code_vacc       := 'VACC.CODE_VACC.' || :OLD.id_vacc;
        :NEW.code_desc_vacc  := 'VACC.CODE_DESC_VACC.' || :OLD.id_vacc;
    END IF;
END;
/
