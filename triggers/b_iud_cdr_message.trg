CREATE OR REPLACE TRIGGER b_iud_cdr_message
    BEFORE INSERT OR UPDATE OR DELETE ON cdr_message
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_cdr_message := 'CDR_MESSAGE.CODE_CDR_MESSAGE.' || :new.id_cdr_message;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_cdr_message;
    ELSIF updating
    THEN
        :new.code_cdr_message := 'CDR_MESSAGE.CODE_CDR_MESSAGE.' || :old.id_cdr_message;
    END IF;
END b_iud_cdr_message;
/
