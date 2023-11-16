CREATE OR REPLACE TRIGGER b_iud_cdr_definition
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_definition
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_name        := 'CDR_DEFINITION.CODE_NAME.' || :new.id_cdr_definition;
        :new.code_description := 'CDR_DEFINITION.CODE_DESCRIPTION.' || :new.id_cdr_definition;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE (t.code_translation = :old.code_name OR t.code_translation = :old.code_description)
           AND t.code_translation LIKE 'CDR\_DEFINITION.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_name        := 'CDR_DEFINITION.CODE_NAME.' || :old.id_cdr_definition;
        :new.code_description := 'CDR_DEFINITION.CODE_DESCRIPTION.' || :old.id_cdr_definition;
    END IF;
END b_iud_cdr_definition;
/
