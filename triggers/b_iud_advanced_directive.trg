CREATE OR REPLACE TRIGGER b_iud_advanced_directive --
    BEFORE INSERT OR UPDATE OR DELETE --
ON advanced_directive --
    REFERENCING NEW AS NEW OLD AS OLD --
    FOR EACH ROW --
DECLARE
    --
    CURSOR c_lang IS
        SELECT id_language
          FROM LANGUAGE l
         WHERE l.id_language IN (1, 2);
BEGIN
    IF inserting
    THEN
        :NEW.code_advanced_directive := 'ADVANCED_DIRECTIVE.CODE_ADVANCED_DIRECTIVE.' || :NEW.id_advanced_directive;
        :NEW.code_label              := 'ADVANCED_DIRECTIVE.CODE_LABEL.' || :NEW.id_advanced_directive;
        :NEW.adw_last_update         := SYSDATE;
        FOR wrec_lang IN c_lang
        LOOP
            INSERT INTO translation
                (id_translation, id_language, code_translation, desc_translation)
                SELECT seq_translation.NEXTVAL, wrec_lang.id_language, t.column_value, NULL
                  FROM TABLE(table_varchar(:NEW.code_advanced_directive, :NEW.code_label)) t
                 WHERE (SELECT 0
                          FROM translation t
                         WHERE t.code_translation = t.column_value
                           AND t.id_language = wrec_lang.id_language) IS NULL;
        END LOOP;
    
    ELSIF updating
    THEN
        :NEW.code_advanced_directive := 'ADVANCED_DIRECTIVE.CODE_ADVANCED_DIRECTIVE.' || :NEW.id_advanced_directive;
        :NEW.code_label              := 'ADVANCED_DIRECTIVE.CODE_LABEL.' || :NEW.id_advanced_directive;
        :NEW.adw_last_update         := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_advanced_directive;
        DELETE FROM translation
         WHERE code_translation = :OLD.code_label;
    END IF;
END b_iud_advanced_directive;
/
