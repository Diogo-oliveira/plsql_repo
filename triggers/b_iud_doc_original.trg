CREATE OR REPLACE
TRIGGER b_iud_doc_original
    BEFORE DELETE OR INSERT OR UPDATE ON doc_original
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_doc_original := 'DOC_ORIGINAL.CODE_DOC_ORIGINAL.' || :NEW.id_doc_original;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_original;
    ELSIF updating
    THEN
        :NEW.code_doc_original := 'DOC_ORIGINAL.CODE_DOC_ORIGINAL.' || :OLD.id_doc_original;
        :NEW.adw_last_update   := SYSDATE;
    END IF;

END;
/
