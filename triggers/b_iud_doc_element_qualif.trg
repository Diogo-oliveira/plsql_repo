CREATE OR REPLACE
TRIGGER b_iud_doc_element_qualif
    BEFORE DELETE OR INSERT OR UPDATE ON doc_element_qualif
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_doc_elem_qualif_close := 'DOC_ELEMENT_QUALIF.CODE_DOC_ELEM_QUALIF_CLOSE.' ||
                                           :NEW.id_doc_element_qualif;
        :NEW.code_doc_elem_qualif_view  := 'DOC_ELEMENT_QUALIF.CODE_DOC_ELEM_QUALIF_VIEW.' ||
                                           :NEW.id_doc_element_qualif;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE REVERSE(code_translation) = REVERSE(:OLD.code_doc_elem_qualif_view)
            OR REVERSE(code_translation) = REVERSE(:OLD.code_doc_elem_qualif_close);

    ELSIF updating
    THEN
        --:NEW.code_doc_elem_qualif_close := 'DOC_ELEMENT_QUALIF.CODE_DOC_ELEM_QUALIF_CLOSE.' ||
        --                                   :OLD.id_doc_element_qualif;
        --:NEW.code_doc_elem_qualif_view  := 'DOC_ELEMENT_QUALIF.CODE_DOC_ELEM_QUALIF_VIEW.' ||
        --                                   :OLD.id_doc_element_qualif;
        :NEW.adw_last_update            := SYSDATE;
    END IF;
END;
/


-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 14/12/2011 10:52
-- CHANGE REASON: [ALERT-209821] Remove unnecessary triggers in metadata tables for Touch-option templates
DECLARE
    l_exists NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO l_exists
      FROM user_objects uo
     WHERE uo.object_name = 'B_IUD_DOC_ELEMENT_QUALIF'
       AND uo.object_type = 'TRIGGER';
    IF l_exists = 1
    THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER B_IUD_DOC_ELEMENT_QUALIF';
    END IF;
END;
/
-- CHANGE END: Ariel Machado