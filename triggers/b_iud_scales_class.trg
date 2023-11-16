CREATE OR REPLACE
TRIGGER b_iud_scales_class
    BEFORE DELETE OR INSERT OR UPDATE ON scales_class
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_scales_class := 'SCALES_CLASS.CODE_SCALES_CLASS.' || :NEW.id_scales_class;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_scales_class;
    ELSIF updating
    THEN
        :NEW.code_scales_class := 'SCALES_CLASS.CODE_SCALES_CLASS.' || :OLD.id_scales_class;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
