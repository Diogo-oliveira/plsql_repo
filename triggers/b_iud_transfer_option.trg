CREATE OR REPLACE
TRIGGER b_iud_transfer_option
    BEFORE DELETE OR INSERT OR UPDATE ON transfer_option
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_transfer_option := 'TRANSFER_OPTION.CODE_TRANSFER_OPTION.' || :NEW.id_transfer_option;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_transfer_option;
    ELSIF updating
    THEN
        :NEW.code_transfer_option := 'TRANSFER_OPTION.CODE_TRANSFER_OPTION.' || :OLD.id_transfer_option;
    END IF;

END b_iud_transfer_option;
/
