CREATE OR REPLACE
TRIGGER b_iud_doc_file_type
    BEFORE DELETE OR INSERT OR UPDATE ON doc_file_type
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_doc_file_type := 'DOC_FILE_TYPE.CODE_DOC_FILE_TYPE.' || :NEW.id_doc_file_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_file_type;
    ELSIF updating
    THEN
        :NEW.code_doc_file_type := 'DOC_FILE_TYPE.CODE_DOC_FILE_TYPE.' || :OLD.id_doc_file_type;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
