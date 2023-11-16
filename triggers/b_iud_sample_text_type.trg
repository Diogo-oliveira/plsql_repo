CREATE OR REPLACE
TRIGGER b_iud_sample_text_type
    BEFORE DELETE OR INSERT OR UPDATE ON sample_text_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sample_text_type := 'SAMPLE_TEXT_TYPE.CODE_SAMPLE_TEXT_TYPE.' || :NEW.id_sample_text_type;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sample_text_type;
    ELSIF updating
    THEN
        :NEW.code_sample_text_type := 'SAMPLE_TEXT_TYPE.CODE_SAMPLE_TEXT_TYPE.' || :OLD.id_sample_text_type;
    END IF;
END;
/
