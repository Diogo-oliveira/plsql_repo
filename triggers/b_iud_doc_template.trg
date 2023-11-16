-- CHANGED BY: Ariel Machado
-- CHANGED DATE: 2009-MAR-25
-- CHANGED REASON: ALERT-12094 Touch-option: support for bilateral templates

--Update DOC_TEMPLATE trigger for XML Validation
CREATE OR REPLACE TRIGGER b_iud_doc_template
    BEFORE DELETE OR INSERT OR UPDATE ON doc_template
    FOR EACH ROW

DECLARE
    CURSOR c_translate IS
        SELECT id_translation
          FROM translation
         WHERE code_translation = :OLD.code_doc_template;

    xmldata xmltype;
BEGIN
    IF inserting
    THEN
        :NEW.code_doc_template := 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || :NEW.id_doc_template;
        :NEW.adw_last_update   := SYSDATE;
    
        --XML Schema validation for template layout
        xmldata := :NEW.template_layout;
        IF xmldata IS NOT NULL
        THEN
            xmltype.schemavalidate(xmldata);
        END IF;
    ELSIF deleting
    THEN
        FOR wrec_translate IN c_translate
        LOOP
            DELETE FROM translation
             WHERE id_translation = wrec_translate.id_translation;
        END LOOP;
    ELSIF updating
    THEN
        :NEW.code_doc_template := 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || :OLD.id_doc_template;
        :NEW.adw_last_update   := SYSDATE;
    
        --XML Schema validation for template layout
        xmldata := :NEW.template_layout;
        IF xmldata IS NOT NULL
        THEN
            xmltype.schemavalidate(xmldata);
        END IF;
    END IF;
END;
/
-- CHANGE END: Ariel Machado