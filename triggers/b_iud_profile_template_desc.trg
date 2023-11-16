create or replace trigger B_IUD_PROFILE_TEMPLATE_DESC
  before DELETE OR INSERT OR UPDATE on profile_template_desc  
  for each row
DECLARE
    CURSOR c_lang IS
        SELECT DISTINCT id_language
          FROM LANGUAGE l
         WHERE l.id_language IN (1, 2, 3);

    CURSOR c_lang_seq IS
        SELECT seq_translation.NEXTVAL
          FROM dual;
    wseq translation.id_translation%TYPE;
    CURSOR c_translate IS
        SELECT id_translation
          FROM translation
         WHERE code_translation = :OLD.code_profile_template_desc;
BEGIN
    IF inserting
    THEN
        :NEW.code_profile_template_desc := 'PROFILE_TEMPLATE_DESC.CODE_PROFILE_TEMPLATE_DESC.' ||
                                           :NEW.id_profile_template_desc;
        FOR wrec_lang IN c_lang
        LOOP
            OPEN c_lang_seq;
            FETCH c_lang_seq
                INTO wseq;
            CLOSE c_lang_seq;
        
            BEGIN INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (wseq, wrec_lang.id_language, :NEW.code_profile_template_desc, NULL); EXCEPTION WHEN dup_val_on_index THEN NULL; END;
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
        :NEW.code_profile_template_desc := 'PROFILE_TEMPLATE_DESC.CODE_PROFILE_TEMPLATE_DESC.' ||
                                           :OLD.id_profile_template_desc;
        :NEW.adw_last_update            := SYSDATE;
    END IF;
END b_iud_profile_template_desc;
/
