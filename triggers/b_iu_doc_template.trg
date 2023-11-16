CREATE OR REPLACE TRIGGER b_iud_doc_template
    BEFORE DELETE OR INSERT OR UPDATE ON doc_template
    FOR EACH ROW

DECLARE
    xmldata xmltype;
BEGIN
    IF inserting
    THEN
        --XML Schema validation for template layout
        xmldata := :NEW.template_layout;
        IF xmldata IS NOT NULL
        THEN
            xmltype.schemavalidate(xmldata);
        END IF;
    ELSIF updating
    THEN
        --XML Schema validation for template layout
        xmldata := :NEW.template_layout;
        IF xmldata IS NOT NULL
        THEN
            xmltype.schemavalidate(xmldata);
        END IF;
    END IF;
END;
/
