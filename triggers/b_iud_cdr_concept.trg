CREATE OR REPLACE TRIGGER b_iud_cdr_concept
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_concept
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_cdr_concept := 'CDR_CONCEPT.CODE_CDR_CONCEPT.' || :new.id_cdr_concept;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_cdr_concept
           AND t.code_translation LIKE 'CDR\_CONCEPT.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_cdr_concept := 'CDR_CONCEPT.CODE_CDR_CONCEPT.' || :old.id_cdr_concept;
    END IF;
END b_iud_cdr_concept;
/
