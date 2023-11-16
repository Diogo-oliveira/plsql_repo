CREATE OR REPLACE TRIGGER b_iud_cdr_action
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_action
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_cdr_action := 'CDR_ACTION.CODE_CDR_ACTION.' || :new.id_cdr_action;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_cdr_action
           AND t.code_translation LIKE 'CDR\_ACTION.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_cdr_action := 'CDR_ACTION.CODE_CDR_ACTION.' || :old.id_cdr_action;
    END IF;
END b_iud_cdr_action;
/
