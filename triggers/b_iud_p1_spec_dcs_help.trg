CREATE OR REPLACE TRIGGER B_IUD_P1_SPEC_DCS_HELP
 BEFORE DELETE OR INSERT OR UPDATE
 ON P1_SPEC_DCS_HELP
 FOR EACH ROW
-- PL/SQL Block
DECLARE
    CURSOR c_lang IS
        SELECT DISTINCT id_language
          FROM LANGUAGE l
         WHERE l.id_language IN (1, 2);

    CURSOR c_lang_seq IS
        SELECT seq_translation.NEXTVAL
          FROM dual;
    wseq translation.id_translation%TYPE;
    CURSOR c_translate1 IS
        SELECT id_translation
          FROM translation
         WHERE code_translation = :OLD.code_title;
    CURSOR c_translate2 IS
        SELECT id_translation
          FROM translation
         WHERE code_translation = :OLD.code_text;
BEGIN
    IF inserting
    THEN
        :NEW.code_title := 'P1_SPEC_DCS_HELP.CODE_TITLE.' || :NEW.id_spec_dcs_help;
        :NEW.code_text  := 'P1_SPEC_DCS_HELP.CODE_TEXT.' || :NEW.id_spec_dcs_help;
        FOR wrec_lang IN c_lang
        LOOP
            OPEN c_lang_seq;
            FETCH c_lang_seq
                INTO wseq;
            CLOSE c_lang_seq;
            BEGIN INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (wseq, wrec_lang.id_language, :NEW.code_title, NULL); EXCEPTION WHEN dup_val_on_index THEN NULL; END;
            OPEN c_lang_seq;
            FETCH c_lang_seq
                INTO wseq;
            CLOSE c_lang_seq;
            BEGIN INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (wseq, wrec_lang.id_language, :NEW.code_text, NULL); EXCEPTION WHEN dup_val_on_index THEN NULL; END;
        END LOOP;
        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        FOR wrec_translate IN c_translate1
        LOOP
            DELETE FROM translation
             WHERE id_translation = wrec_translate.id_translation;
        END LOOP;
        FOR wrec_translate IN c_translate2
        LOOP
            DELETE FROM translation
             WHERE id_translation = wrec_translate.id_translation;
        END LOOP;
    ELSIF updating
    THEN
        :NEW.code_title      := 'P1_SPEC_DCS_HELP.CODE_TITLE.' || :OLD.id_spec_dcs_help;
        :NEW.code_text       := 'P1_SPEC_DCS_HELP.CODE_TEXT.' || :OLD.id_spec_dcs_help;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/

drop trigger B_IUD_P1_SPEC_DCS_HELP;
