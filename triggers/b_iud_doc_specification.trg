CREATE OR REPLACE
TRIGGER b_iud_doc_specification
    BEFORE DELETE OR INSERT OR UPDATE ON doc_specification
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_doc_specification := 'DOC_SPECIFICATION.CODE_DOC_SPECIFICATION.' || :NEW.id_doc_specification;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_specification;
    ELSIF updating
    THEN
        :NEW.code_doc_specification := 'DOC_SPECIFICATION.CODE_DOC_SPECIFICATION.' || :OLD.id_doc_specification;
        :NEW.adw_last_update        := SYSDATE;
    END IF;

END;
/
