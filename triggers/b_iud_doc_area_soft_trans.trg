
CREATE OR REPLACE TRIGGER b_iud_doc_area_soft_trans
    BEFORE DELETE OR INSERT OR UPDATE ON doc_area_soft_trans
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
DECLARE
    CURSOR c_lang IS
        SELECT DISTINCT id_language
          FROM LANGUAGE l
         WHERE l.id_language IN (1, 2);
BEGIN
    IF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_doc_area;
        DELETE FROM translation
         WHERE code_translation = :OLD.code_abbreviation;
        RETURN;
    END IF;

    :NEW.code_doc_area     := 'DOC_AREA_SOFT_TRANS.CODE_DOC_AREA.' || :NEW.id_doc_area_soft_trans;
    :NEW.code_abbreviation := 'DOC_AREA_SOFT_TRANS.CODE_ABBREVIATION.' || :NEW.id_doc_area_soft_trans;
    :NEW.adw_last_update   := SYSDATE;

    IF inserting
    THEN
        FOR wrec_lang IN c_lang
        LOOP
            INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (seq_translation.NEXTVAL, wrec_lang.id_language, :NEW.code_doc_area, NULL);
            INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (seq_translation.NEXTVAL, wrec_lang.id_language, :NEW.code_abbreviation, NULL);
        END LOOP;
    END IF;

END b_iud_doc_area;
/
