CREATE OR REPLACE TRIGGER B_IUD_DOC_AREA
BEFORE DELETE OR INSERT OR UPDATE
ON DOC_AREA 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
    CURSOR c_lang IS
        SELECT DISTINCT id_language
          FROM LANGUAGE l
         WHERE l.id_language IN (1, 2);

    CURSOR c_lang_seq IS
        SELECT seq_translation.NEXTVAL
          FROM dual;
    wseq translation.id_translation%TYPE;

    CURSOR c_translate IS
        SELECT id_translation
          FROM translation
         WHERE code_translation = :OLD.code_doc_area;
BEGIN
    IF inserting
    THEN
        :NEW.code_doc_area := 'DOC_AREA.CODE_DOC_AREA.' || :NEW.id_doc_area;
    
        FOR wrec_lang IN c_lang
        LOOP
            OPEN c_lang_seq;
            FETCH c_lang_seq
                INTO wseq;
            CLOSE c_lang_seq;
        
            INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (wseq, wrec_lang.id_language, :NEW.code_doc_area, NULL);
        END LOOP;
    
        :NEW.adw_last_update := SYSDATE;
    
    ELSIF deleting
    THEN
        FOR wrec_translate IN c_translate
        LOOP
            DELETE FROM translation
             WHERE id_translation = wrec_translate.id_translation;
        END LOOP;
    ELSIF updating
    THEN
        :NEW.code_doc_area   := 'DOC_AREA.CODE_DOC_AREA.' || :OLD.id_doc_area;
        :NEW.adw_last_update := SYSDATE;
    END IF;

END b_iud_doc_area;
/

drop trigger B_IUD_DOC_AREA;
