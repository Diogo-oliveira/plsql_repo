CREATE OR REPLACE TRIGGER B_IU_SR_CHKLIST
BEFORE INSERT OR UPDATE
OF ID_SR_CHKLIST
  ,ID_SR_CHKLIST_PARENT
  ,CODE_SR_CHKLIST
  ,FLG_MANUAL_CHK_YN
  ,FLG_MANDATORY_YN
ON ALERT.SR_CHKLIST 
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
         WHERE code_translation = :OLD.code_sr_chklist;

BEGIN

    IF inserting
    THEN
        SELECT seq_sr_chklist.NEXTVAL
          INTO :NEW.id_sr_chklist
          FROM dual;
        :NEW.code_sr_chklist := 'SR_CHKLIST.CODE_SR_CHKLIST.' || :NEW.id_sr_chklist;
        FOR wrec_lang IN c_lang
        LOOP
            OPEN c_lang_seq;
            FETCH c_lang_seq
                INTO wseq;
            CLOSE c_lang_seq;
            BEGIN INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
            VALUES
                (wseq, wrec_lang.id_language, :NEW.code_sr_chklist, NULL); EXCEPTION WHEN dup_val_on_index THEN NULL; END;
        END LOOP;
    
    ELSIF deleting
    THEN
        FOR wrec_translate IN c_translate
        LOOP
            DELETE FROM translation
             WHERE id_translation = wrec_translate.id_translation;
        END LOOP;
    
    ELSIF updating
    THEN
        :NEW.code_sr_chklist := 'SR_CHKLIST.CODE_SR_CHKLIST.' || :OLD.id_sr_chklist;
    END IF;

END;

DROP TRIGGER B_IU_SR_CHKLIST;
/
