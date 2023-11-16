CREATE OR REPLACE TRIGGER b_iud_cdr_instance
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_instance
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_description := 'CDR_INSTANCE.CODE_DESCRIPTION.' || :new.id_cdr_instance;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_description
           AND t.code_translation LIKE 'CDR\_INSTANCE.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_description := 'CDR_INSTANCE.CODE_DESCRIPTION.' || :old.id_cdr_instance;
    END IF;
END b_iud_cdr_instance;
/
