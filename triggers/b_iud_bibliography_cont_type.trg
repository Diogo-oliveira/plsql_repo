CREATE OR REPLACE
TRIGGER b_iud_bibliography_cont_type
    BEFORE DELETE OR INSERT OR UPDATE ON bibliography_content_type
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_content_type := 'BIBLIOGRAPHY_CONTENT_TYPE.CODE_CONTENT_TYPE.' || :NEW.id_bibliography_content_type;
        :NEW.adw_last_update   := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_content_type;
    ELSIF updating
    THEN
        :NEW.code_content_type := 'BIBLIOGRAPHY_CONTENT_TYPE.CODE_CONTENT_TYPE.' || :OLD.id_bibliography_content_type;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
