CREATE OR REPLACE
TRIGGER b_iud_doc_area_software
    BEFORE DELETE OR INSERT OR UPDATE ON doc_area_software
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_area
            OR code_translation = :OLD.code_abbreviation;
        RETURN;
    END IF;

    :NEW.code_doc_area     := 'DOC_AREA_SOFTWARE.CODE_DOC_AREA.' || :NEW.id_doc_area_software;
    :NEW.code_abbreviation := 'DOC_AREA_SOFTWARE.CODE_ABBREVIATION.' || :NEW.id_doc_area_software;
    :NEW.adw_last_update   := SYSDATE;
END b_iud_doc_area;
/
