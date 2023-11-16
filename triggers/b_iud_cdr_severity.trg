CREATE OR REPLACE TRIGGER b_iud_cdr_severity
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_severity
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_cdr_severity := 'CDR_SEVERITY.CODE_CDR_SEVERITY.' || :new.id_cdr_severity;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_cdr_severity
           AND t.code_translation LIKE 'CDR\_SEVERITY.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_cdr_severity := 'CDR_SEVERITY.CODE_CDR_SEVERITY.' || :old.id_cdr_severity;
    END IF;
END b_iud_cdr_severity;
/
