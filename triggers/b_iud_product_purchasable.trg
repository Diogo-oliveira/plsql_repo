

CREATE OR REPLACE TRIGGER B_IUD_PRODUCT_PURCHASABLE
  BEFORE DELETE OR INSERT OR UPDATE
 ON PRODUCT_PURCHASABLE
 FOR EACH ROW
-- PL/SQL Block
DECLARE
    CURSOR c_lang IS
        SELECT DISTINCT id_language
          FROM LANGUAGE;
    CURSOR c_lang_seq IS
        SELECT seq_translation.NEXTVAL
          FROM dual;
    wseq translation.id_translation%TYPE;

    CURSOR c_translate IS
        SELECT id_translation
          FROM translation
         WHERE code_translation = :OLD.code_product_purchasable;

    CURSOR c_transl IS
        SELECT id_translation
          FROM translation
         WHERE code_translation = :OLD.code_product_purchasable_desc;
BEGIN
    IF inserting
    THEN
        :NEW.code_product_purchasable      := 'PRODUCT_PURCHASABLE.CODE_PRODUCT_PURCHASABLE.' ||
                                              :NEW.id_product_purchasable;
        :NEW.code_product_purchasable_desc := 'PRODUCT_PURCHASABLE.CODE_PRODUCT_PURCHASABLE_DESC.' ||
                                              :NEW.id_product_purchasable;
    
        FOR wrec_lang IN c_lang
        LOOP
            OPEN c_lang_seq;
            FETCH c_lang_seq
                INTO wseq;
            CLOSE c_lang_seq;
        
            INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (wseq, wrec_lang.id_language, :NEW.code_product_purchasable, NULL);
        
            OPEN c_lang_seq;
            FETCH c_lang_seq
                INTO wseq;
            CLOSE c_lang_seq;
        
            INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (wseq, wrec_lang.id_language, :NEW.code_product_purchasable_desc, NULL);
        END LOOP;
    
        :NEW.adw_last_update := SYSDATE;
    
    ELSIF deleting
    THEN
        FOR wrec_translate IN c_translate
        LOOP
            DELETE FROM translation
             WHERE id_translation = wrec_translate.id_translation;
        END LOOP;
        FOR wrec_transl IN c_transl
        LOOP
            DELETE FROM translation
             WHERE id_translation = wrec_transl.id_translation;
        END LOOP;
    ELSIF updating
    THEN
        :NEW.code_product_purchasable := 'PRODUCT_PURCHASABLE.CODE_PRODUCT_PURCHASABLE.' || :OLD.id_product_purchasable;
        :NEW.code_product_purchasable := 'PRODUCT_PURCHASABLE.CODE_PRODUCT_PURCHASABLE_DESC.' ||
                                         :OLD.id_product_purchasable;
        :NEW.adw_last_update          := SYSDATE;
    END IF;
END b_iud_product_purchasable;