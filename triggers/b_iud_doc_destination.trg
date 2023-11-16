CREATE OR REPLACE
TRIGGER b_iud_doc_destination
    BEFORE DELETE OR INSERT OR UPDATE ON doc_destination
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_doc_destination := 'DOC_TYPE.CODE_DOC_DESTINATION.' || :NEW.id_doc_destination;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_destination;
    ELSIF updating
    THEN
        :NEW.code_doc_destination := 'DOC_TYPE.CODE_DOC_DESTINATION.' || :OLD.id_doc_destination;
        :NEW.adw_last_update      := SYSDATE;
    END IF;
END;
/
