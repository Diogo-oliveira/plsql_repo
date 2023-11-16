CREATE OR REPLACE
TRIGGER b_iud_doc_quantification
    BEFORE DELETE OR INSERT OR UPDATE ON doc_quantification
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_doc_quantification := 'DOC_QUANTIFICATION.CODE_DOC_QUANTIFICATION.' || :NEW.id_doc_quantification;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_quantification;
    ELSIF updating
    THEN
        :NEW.code_doc_quantification := 'DOC_QUANTIFICATION.CODE_DOC_QUANTIFICATION.' || :OLD.id_doc_quantification;
        :NEW.adw_last_update         := SYSDATE;
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
     WHERE uo.object_name = 'B_IUD_DOC_QUANTIFICATION'
       AND uo.object_type = 'TRIGGER';
    IF l_exists = 1
    THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER B_IUD_DOC_QUANTIFICATION';
    END IF;
END;
/
-- CHANGE END: Ariel Machado