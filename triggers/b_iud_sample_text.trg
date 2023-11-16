CREATE OR REPLACE
TRIGGER b_iud_sample_text
    BEFORE DELETE OR INSERT OR UPDATE ON sample_text
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_title_sample_text := 'SAMPLE_TEXT.CODE_TITLE_SAMPLE_TEXT.' || :NEW.id_sample_text;
        :NEW.code_desc_sample_text  := 'SAMPLE_TEXT.CODE_DESC_SAMPLE_TEXT.' || :NEW.id_sample_text;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_title_sample_text
            OR code_translation = :OLD.code_desc_sample_text;
    ELSIF updating
    THEN
        :NEW.code_title_sample_text := 'SAMPLE_TEXT.CODE_TITLE_SAMPLE_TEXT.' || :OLD.id_sample_text;
        :NEW.code_desc_sample_text  := 'SAMPLE_TEXT.CODE_DESC_SAMPLE_TEXT.' || :OLD.id_sample_text;
    END IF;
END;
/
