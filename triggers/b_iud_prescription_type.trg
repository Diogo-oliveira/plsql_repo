CREATE OR REPLACE
TRIGGER b_iud_prescription_type
    BEFORE DELETE OR INSERT OR UPDATE ON prescription_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_prescription_type := 'PRESCRIPTION_TYPE.CODE_PRESCRIPTION_TYPE.' || :NEW.id_prescription_type;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_prescription_type;
    ELSIF updating
    THEN
        :NEW.code_prescription_type := 'PRESCRIPTION_TYPE.CODE_PRESCRIPTION_TYPE.' || :OLD.id_prescription_type;
        :NEW.adw_last_update        := SYSDATE;
    END IF;
END;
/
