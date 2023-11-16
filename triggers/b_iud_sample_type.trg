CREATE OR REPLACE
TRIGGER b_iud_sample_type
    BEFORE DELETE OR INSERT OR UPDATE ON sample_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sample_type := 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || :NEW.id_sample_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sample_type;
    ELSIF updating
    THEN
        :NEW.code_sample_type := 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || :OLD.id_sample_type;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
