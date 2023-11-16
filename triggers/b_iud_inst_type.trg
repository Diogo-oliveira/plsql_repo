CREATE OR REPLACE
TRIGGER b_iud_inst_type
    BEFORE DELETE OR INSERT OR UPDATE ON inst_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_inst_type := 'INST_TYPE.CODE_INST_TYPE.' || :NEW.id_inst_type;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_inst_type;
    ELSIF updating
    THEN
        :NEW.code_inst_type  := 'INST_TYPE.CODE_INST_TYPE.' || :OLD.id_inst_type;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
