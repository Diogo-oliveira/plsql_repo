CREATE OR REPLACE TRIGGER b_iud_cdr_type
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_type
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_cdr_type := 'CDR_TYPE.CODE_CDR_TYPE.' || :new.id_cdr_type;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_cdr_type
           AND t.code_translation LIKE 'CDR\_TYPE.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_cdr_type := 'CDR_TYPE.CODE_CDR_TYPE.' || :old.id_cdr_type;
    END IF;
END b_iud_cdr_type;
/
