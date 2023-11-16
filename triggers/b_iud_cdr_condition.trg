CREATE OR REPLACE TRIGGER b_iud_cdr_condition
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_condition
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_cdr_condition := 'CDR_CONDITION.CODE_CDR_CONDITION.' || :new.id_cdr_condition;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_cdr_condition
           AND t.code_translation LIKE 'CDR\_CONDITION.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_cdr_condition := 'CDR_CONDITION.CODE_CDR_CONDITION.' || :old.id_cdr_condition;
    END IF;
END b_iud_cdr_condition;
/
