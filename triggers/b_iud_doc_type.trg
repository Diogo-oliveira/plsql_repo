CREATE OR REPLACE
TRIGGER b_iud_doc_type
    BEFORE DELETE OR INSERT OR UPDATE ON doc_type
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_doc_type := 'DOC_TYPE.CODE_DOC_TYPE.' || :NEW.id_doc_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_type;
    ELSIF updating
    THEN
        :NEW.code_doc_type   := 'DOC_TYPE.CODE_DOC_TYPE.' || :OLD.id_doc_type;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
