-- CHANGED BY: Ariel Machado
-- CHANGED DATE: 2009-MAR-25
-- CHANGED REASON: ALERT-12094 Touch-option: support for bilateral templates
CREATE OR REPLACE TRIGGER b_iu_doc_template_area
    BEFORE INSERT OR UPDATE ON doc_template_area
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :NEW.action_subject := 'DOC_TEMPLATE_AREA.ACTION_SUBJECT.' || :NEW.id_doc_template || '.' || :NEW.id_doc_area;
    
    ELSIF updating
    THEN
        :NEW.action_subject := 'DOC_TEMPLATE_AREA.ACTION_SUBJECT.' || :OLD.id_doc_template || '.' || :OLD.id_doc_area;
    END IF;
END;
/
-- CHANGE END: Ariel Machado

-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 14/12/2011 10:52
-- CHANGE REASON: [ALERT-209821] Remove unnecessary triggers in metadata tables for Touch-option templates
DECLARE
    l_exists NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO l_exists
      FROM user_objects uo
     WHERE uo.object_name = 'B_IU_DOC_TEMPLATE_AREA'
       AND uo.object_type = 'TRIGGER';
    IF l_exists = 1
    THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER B_IU_DOC_TEMPLATE_AREA';
    END IF;
END;
/
-- CHANGE END: Ariel Machado